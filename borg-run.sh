#!/bin/bash -ue

# from https://borgbackup.readthedocs.io/en/stable/deployment/automated-local.html

set -e

# leave time for the automatic partition enumeration by the kernel due to fuzzy udev rules
sleep 5

MOUNTPOINT=/media/crypt_ext
LUKS_BLOCK_UUID="c9e85b9d-b0e3-41f7-b1c7-6f9b76082e31"
LUKS_CRYPT_UUID="fdd44fbd-4673-4454-85f7-36feae95e42d"
LUKS_DEVICE="crypt_ext"
LUKS_KEYFILE="/etc/borg/crypt_ext.luks"

TARGET=${MOUNTPOINT}/borg/dent.borg
DATE=$(date --iso-8601)-$(hostname)

export BORG_REPO="$TARGET"
export BORG_PASSPHRASE="HlH9GZl5jassnfXAvSmEI5ycr9VrHx6Z"

if lsblk --output uuid | grep $LUKS_BLOCK_UUID; then
	echo "Found LUKS block device $LUKS_BLOCK_UUID"
else
	echo "LUKS block device not found!"
	exit 1
fi

if mount | grep $MOUNTPOINT; then
	echo "$MOUNTPOINT already mounted"
elif mount | grep $LUKS_CRYPT_UUID; then
	echo "Found LUKS crypt device"
else
	echo "No LUKS crypt device found; trying to open" 
	cryptsetup luksOpen -d $LUKS_KEYFILE $(realpath /dev/disk/by-uuid/$LUKS_BLOCK_UUID) $LUKS_DEVICE
	echo "Mounting LUKS device $LUKS_DEVICE to $MOUNTPOINT"
	mount /dev/mapper/$LUKS_DEVICE $MOUNTPOINT 
fi

#
# Create backups
#

# Options for borg create
BORG_OPTS="--stats --one-file-system --compression lz4 --checkpoint-interval 86400"

# No one can answer if Borg asks these questions, it is better to just fail quickly
# instead of hanging.
export BORG_RELOCATED_REPO_ACCESS_IS_OK=no
export BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK=no

# Log Borg version
borg --version

borg create $BORG_OPTS \
  ::etc-$DATE-$$ \
  /etc

borg create $BORG_OPTS \
  --exclude 'sh:/var/home/*/Downloads' \
  --exclude 'sh:/var/home/*/.cache' \
  ::home-$DATE-$$ \
  /var/home


#
# Pruning
#

for prefix in "home" "etc"; do
	borg prune \
	  --list \
	  --prefix "$prefix" \
	  --show-rc \
	  --keep-daily 7 \
	  --keep-weekly 4 \
	  --keep-monthly 12
done

#
# Close device
#
sync
umount $MOUNTPOINT
cryptsetup luksClose $LUKS_DEVICE
