#!/usr/bin/env bash
# Install Bluetooth USB autosuspend workarounds. Run as root.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"

install -d /etc/udev/rules.d /etc/modprobe.d /etc/limine-entry-tool.d
install -m 644 "$here/51-bluetooth-no-autosuspend.rules" /etc/udev/rules.d/51-bluetooth-no-autosuspend.rules
install -m 644 "$here/btusb-no-autosuspend.conf" /etc/modprobe.d/btusb-no-autosuspend.conf
install -m 644 "$here/usbcore-autosuspend.conf" /etc/limine-entry-tool.d/usbcore-autosuspend.conf

if [[ -e /sys/module/btusb/parameters/enable_autosuspend ]]; then
  echo N > /sys/module/btusb/parameters/enable_autosuspend
fi

for d in /sys/bus/usb/devices/*; do
  [[ -f "$d/idVendor" && -f "$d/idProduct" ]] || continue
  if [[ $(<"$d/idVendor") == 2c7c && $(<"$d/idProduct") == 7009 ]]; then
    echo on > "$d/power/control"
    echo -1 > "$d/power/autosuspend"
  fi
done

udevadm control --reload
udevadm trigger --action=add --subsystem-match=usb

if command -v limine-mkinitcpio >/dev/null; then
  limine-mkinitcpio
fi
