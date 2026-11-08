"""Exercise Stow composition and rclone controls using temporary homes only."""

import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]


def packages(profile):
    selected = []
    for name in ("omarchy-common", profile):
        for line in (ROOT / "profiles" / f"{name}.stow").read_text().splitlines():
            if line and not line.startswith("#"):
                selected.append(line)
    return selected


def run(*args, **kwargs):
    return subprocess.run(args, capture_output=True, text=True, **kwargs)


class ProfilesTest(unittest.TestCase):
    def test_previews_never_create_links(self):
        for profile in ("omachine", "macbook-m2"):
            with self.subTest(profile=profile), tempfile.TemporaryDirectory() as directory:
                result = run(
                    str(ROOT / "scripts/preview-omarchy-stow.sh"),
                    profile, "--target", directory,
                )
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(list(Path(directory).iterdir()), [])

    def test_m2_keeps_existing_monitor_and_audio_startup_files(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            hypr = home / ".config/hypr"
            hypr.mkdir(parents=True)
            for filename in ("monitors.lua", "autostart.lua"):
                (hypr / filename).write_text("-- Existing laptop setting\n")
            result = run(
                "stow", "--no-folding", f"--dir={ROOT / 'config'}",
                f"--target={home}", *packages("macbook-m2"),
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            for filename in ("monitors.lua", "autostart.lua"):
                self.assertFalse((hypr / filename).is_symlink())
                self.assertEqual((hypr / filename).read_text(), "-- Existing laptop setting\n")
            self.assertTrue((hypr / "input.lua").is_symlink())
            self.assertFalse((home / ".config/omarchy/machine").exists())
            self.assertFalse((home / ".local/bin/kuycon-dp-audio").exists())
            self.assertFalse((home / ".config/rclone/rclone.conf").exists())
            self.assertFalse((home / ".config/omarchy/extensions/omarchy-menu.jsonc").exists())

    def test_desktop_composes_without_overlapping_target_paths(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            command = (
                "stow", "--no-folding", f"--dir={ROOT / 'config'}",
                f"--target={home}", *packages("omachine"),
            )
            for _ in range(2):
                result = run(*command)
                self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(
                (home / ".config/hypr/monitors.lua").resolve(),
                ROOT / "config/omarchy-omachine/.config/hypr/monitors.lua",
            )
            self.assertTrue((home / ".config/hypr/input.lua").is_symlink())
            self.assertTrue((home / ".config/hypr").is_dir())
            self.assertFalse((home / ".config/hypr").is_symlink())
            self.assertTrue((home / ".local/bin/kuycon-dp-audio").is_symlink())

    def test_existing_config_collision_is_reported_and_preserved(self):
        with tempfile.TemporaryDirectory() as directory:
            target = Path(directory) / ".config/hypr/input.lua"
            target.parent.mkdir(parents=True)
            target.write_text("-- Unreviewed local input settings\n")
            original_paths = sorted(Path(directory).rglob("*"))
            result = run(
                str(ROOT / "scripts/preview-omarchy-stow.sh"),
                "omachine", "--target", directory,
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertFalse(target.is_symlink())
            self.assertEqual(target.read_text(), "-- Unreviewed local input settings\n")
            self.assertEqual(sorted(Path(directory).rglob("*")), original_paths)

    def test_unknown_profile_cannot_select_arbitrary_packages(self):
        result = run(str(ROOT / "scripts/preview-omarchy-stow.sh"), "../../macos")
        self.assertEqual(result.returncode, 2)


class RcloneTest(unittest.TestCase):
    def setup_home(self, home, remotes):
        binaries = home / "bin"
        binaries.mkdir()
        control = binaries / "systemctl"
        control.write_text(
            "#!/usr/bin/env python3\n"
            "import json, os, sys\n"
            "with open(os.environ['CALL_LOG'], 'a') as stream:\n"
            "    stream.write(json.dumps(sys.argv[1:]) + '\\n')\n"
        )
        control.chmod(0o755)
        rclone = binaries / "rclone"
        rclone.write_text(
            "#!/usr/bin/env python3\n"
            f"print({remotes!r}, end='')\n"
        )
        rclone.chmod(0o755)
        return dict(
            os.environ, HOME=str(home), PATH=f"{binaries}:{os.environ['PATH']}",
            CALL_LOG=str(home / "calls.jsonl"),
        )

    def test_control_escapes_remote_names(self):
        for remote in ("Shared + Notes", "Team - Library", "Données"):
            with self.subTest(remote=remote), tempfile.TemporaryDirectory() as directory:
                home = Path(directory)
                env = self.setup_home(home, "")
                result = run(
                    str(ROOT / "config/rclone/.local/bin/rclone-mount-control"),
                    "restart", remote, env=env,
                )
                self.assertEqual(result.returncode, 0, result.stderr)
                unit = run("systemd-escape", "--template=rclone-mount@.service", "--", remote).stdout.strip()
                self.assertEqual(
                    json.loads((home / "calls.jsonl").read_text()),
                    ["--user", "restart", unit],
                )

    def test_sharepoint_configuration_and_enable_use_same_unit(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            remote = "Shared + Notes"
            env = self.setup_home(home, f"{remote}:\n")
            result = run(
                str(ROOT / "config/rclone/.local/bin/rclone-mount-enable"),
                remote, "--sharepoint", env=env,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            unit = run("systemd-escape", "--template=rclone-mount@.service", "--", remote).stdout.strip()
            self.assertIn(
                "RCLONE_IGNORE_CHECKSUM=true RCLONE_IGNORE_SIZE=true",
                (home / ".config/systemd/user" / f"{unit}.d/sharepoint.conf").read_text(),
            )
            calls = [json.loads(line) for line in (home / "calls.jsonl").read_text().splitlines()]
            self.assertEqual(calls, [["--user", "daemon-reload"], ["--user", "enable", "--now", unit]])
            self.assertFalse((home / ".config/rclone/rclone.conf").exists())

    def test_unauthenticated_or_invalid_remote_never_starts_service(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            env = self.setup_home(home, "")
            for args in (("Missing",), ("../escape",), ("Bad\nname",)):
                result = run(str(ROOT / "config/rclone/.local/bin/rclone-mount-enable"), *args, env=env)
                self.assertNotEqual(result.returncode, 0)
            self.assertFalse((home / "calls.jsonl").exists())
            self.assertFalse((home / ".config").exists())


if __name__ == "__main__":
    unittest.main()
