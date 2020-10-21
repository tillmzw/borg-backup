
# BORG BACKUPS

Run automatic backups every hour (via systemd timer) and whenever a specific disk is connected (via a udev rule + systemd service).

This disk is expected to be a LUKS encrypted external USB device containing a single volume; 
UUIDs, luks device names und luks encryption keys must be configured manually.

## DIRECT RUN

1. `./borg-run.sh`

## SYSTEMD

1. Enable service: `systemctl enable $(pwd)/borg-backup.service`
2. Enable timer: `systemctl enable --now $(pwd)/borg-backup.timer`

## UDEV

1. Link udev rule to `/etc/udev/rules.d/40-borg.rules`
2. Reload udev rules `udevadm control --reload-rules && udevadm trigger`

