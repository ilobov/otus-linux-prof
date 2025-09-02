#!/bin/bash
disk="/dev/"$(lsblk -o NAME,SIZE,TYPE | grep disk | tac | head -n 1 | cut -d ' ' -f 1)
echo "label: dos" | sfdisk "$disk"
echo "type=83" | sfdisk "$disk"
mkfs -t ext4 "$disk"1
mkdir -p /var/backup
mount "$disk"1 /var/backup
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf > /dev/null
echo "nameserver 8.8.4.4" | sudo tee -a /etc/resolv.conf > /dev/null

