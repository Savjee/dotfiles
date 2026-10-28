# tstack skills

Imported from [t3dotgg/tstack](https://github.com/t3dotgg/tstack) at
commit [`1085050f3baed1ac724caa4a8166145fb2ac88af`](https://github.com/t3dotgg/tstack/tree/1085050f3baed1ac724caa4a8166145fb2ac88af)
on 2026-10-28. The upstream [MIT license](LICENSE) is included here.

The nine imported skills are `babysit-pr`, `council`, `file-pr`, `full-send`, `full-stop`,
`leaving-pr-comments`, `modernize`, `sol-loop`, and `takeover`. Their files
are copied unchanged, including supporting scripts and agent metadata.
The executable permission on `babysit-pr/scripts/pr-wait` matches upstream.

`full-send` is included because `full-stop` reads its workflow. Use `full-stop`
to prepare a PR for manual merging; it explicitly prohibits merging and
overrides the merge permission in `full-send`.

The canonical copies live in `config/agents/.agents/skills/`. Relative symlinks
under the same Stow package expose all shared skills to Claude Code and Codex.
OpenCode and Cursor also discover `~/.agents/skills/` directly. Install on each
machine with the command in the [main README](../../README.md#shared-agent-skills-linux-and-macos).

For an upstream update, review a specific commit and copy all nine skill
directories, retaining file modes and this license.
Update this provenance record and keep the harness symlinks in sync if the
skill names change.
