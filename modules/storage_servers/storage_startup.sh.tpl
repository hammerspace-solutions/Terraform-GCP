#!/bin/bash
# Storage Server Startup Script

set -e

# Update system
apt-get update

# Install storage server packages
apt-get install -y \
    nfs-kernel-server \
    samba \
    mdadm \
    lvm2 \
    xfsprogs \
    smartmontools

# Create storage mount point
mkdir -p ${mount_point}

# Set up data disks
%{ if disk_count > 0 ~}
# Wait for disks to be attached
sleep 10

# Find all attached data disks
DISKS=$(lsblk -nd -o NAME,TYPE | grep disk | grep -v sda | awk '{print "/dev/"$1}')

if [ ! -z "$DISKS" ]; then
    DISK_COUNT=$(echo "$DISKS" | wc -w)

    # Set up RAID if multiple disks
    if [ $DISK_COUNT -gt 1 ] && [ "${raid_level}" != "linear" ]; then
        # Create RAID array
        yes | mdadm --create /dev/md0 \
            --level=${raid_level} \
            --raid-devices=$DISK_COUNT \
            $DISKS \
            --force

        # Wait for RAID to sync
        sleep 5

        # Create XFS filesystem on RAID array
        mkfs.xfs -f /dev/md0

        # Mount RAID array
        mount /dev/md0 ${mount_point}

        # Add to fstab
        echo "/dev/md0 ${mount_point} xfs defaults,nofail 0 0" >> /etc/fstab

        # Save RAID configuration
        mdadm --detail --scan >> /etc/mdadm/mdadm.conf
        update-initramfs -u
    else
        # Single disk or linear setup
        if [ $DISK_COUNT -eq 1 ]; then
            DISK=$(echo "$DISKS" | head -n1)
            mkfs.xfs -f $DISK
            mount $DISK ${mount_point}

            # Add to fstab
            UUID=$(blkid -s UUID -o value $DISK)
            echo "UUID=$UUID ${mount_point} xfs defaults,nofail 0 0" >> /etc/fstab
        else
            # Linear concatenation with LVM
            # Create physical volumes
            for DISK in $DISKS; do
                pvcreate $DISK
            done

            # Create volume group
            vgcreate storage_vg $DISKS

            # Create logical volume using all space
            lvcreate -l 100%FREE -n storage_lv storage_vg

            # Create filesystem
            mkfs.xfs -f /dev/storage_vg/storage_lv

            # Mount
            mount /dev/storage_vg/storage_lv ${mount_point}

            # Add to fstab
            echo "/dev/storage_vg/storage_lv ${mount_point} xfs defaults,nofail 0 0" >> /etc/fstab
        fi
    fi

    # Set permissions
    chmod 755 ${mount_point}
fi
%{ endif ~}

# Configure NFS exports
cat > /etc/exports <<EOF
${mount_point} *(rw,sync,no_subtree_check,no_root_squash)
EOF

# Export the filesystem
exportfs -a

# Start NFS server
systemctl enable nfs-kernel-server
systemctl restart nfs-kernel-server

# Configure Samba
cat > /etc/samba/smb.conf <<EOF
[global]
   workgroup = WORKGROUP
   server string = Storage Server
   security = user
   map to guest = Bad User
   log file = /var/log/samba/log.%m
   max log size = 50

[storage]
   path = ${mount_point}
   browseable = yes
   writable = yes
   guest ok = yes
   read only = no
   create mask = 0755
EOF

# Restart Samba
systemctl enable smbd nmbd
systemctl restart smbd nmbd

# Enable performance tuning
cat >> /etc/sysctl.conf <<EOF
# Storage server performance tuning
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728
net.core.netdev_max_backlog = 30000
net.ipv4.tcp_congestion_control = htcp
net.ipv4.tcp_mtu_probing = 1
vm.dirty_ratio = 30
vm.dirty_background_ratio = 5
EOF

sysctl -p

echo "Storage server setup complete"