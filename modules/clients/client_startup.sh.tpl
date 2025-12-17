#!/bin/bash
# Client Instance Startup Script

set -e

# Update system
apt-get update

# Install NFS client utilities
apt-get install -y nfs-common

# Create mount point
mkdir -p ${mount_point}

# If we have data disks, set them up
%{ if disk_count > 0 ~}
# Wait for disks to be attached
sleep 10

# Find all attached data disks
DISKS=$(lsblk -nd -o NAME,TYPE | grep disk | grep -v sda | awk '{print "/dev/"$1}')

if [ ! -z "$DISKS" ]; then
    # Create filesystem on each disk
    for DISK in $DISKS; do
        if ! blkid $DISK; then
            mkfs.ext4 -F $DISK
        fi
    done

    # If multiple disks and RAID is desired, set up RAID
    DISK_COUNT=$(echo "$DISKS" | wc -w)

    if [ $DISK_COUNT -gt 1 ]; then
        # Install mdadm for RAID
        apt-get install -y mdadm

        # Create RAID array
        mdadm --create /dev/md0 --level=${raid_level} --raid-devices=$DISK_COUNT $DISKS --force

        # Create filesystem on RAID array
        mkfs.ext4 -F /dev/md0

        # Mount RAID array
        mount /dev/md0 ${mount_point}

        # Add to fstab
        echo "/dev/md0 ${mount_point} ext4 defaults 0 0" >> /etc/fstab

        # Save RAID configuration
        mdadm --detail --scan >> /etc/mdadm/mdadm.conf
    else
        # Single disk, just mount it
        DISK=$(echo "$DISKS" | head -n1)
        mount $DISK ${mount_point}

        # Add to fstab
        UUID=$(blkid -s UUID -o value $DISK)
        echo "UUID=$UUID ${mount_point} ext4 defaults 0 0" >> /etc/fstab
    fi
fi
%{ endif ~}

# Install client tools
apt-get install -y \
    iotop \
    sysstat \
    htop \
    fio \
    python3-pip

# Set up performance monitoring
systemctl enable sysstat
systemctl start sysstat

echo "Client setup complete"