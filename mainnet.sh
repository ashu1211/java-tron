#!/bin/bash

# Update and install necessary packages
sudo apt-get update -y
sudo apt-get install git -y
sudo apt install openjdk-8-jre-headless -y
sudo apt install default-jre -y
sudo apt install default-jdk -y
sudo apt-get update -y
sudo apt-get install aria2 -y
sudo apt-get install jq -y
sudo apt install nload -y
sudo apt install sysstat -y
sudo apt-get install xfsprogs -y

# Create the /data directory
sudo mkdir -p /data

# Find the largest unmounted partition
disk2=$(lsblk -nx size -o kname | tail -1 | awk '{printf "/dev/" $1}')

# Format the partition with the XFS filesystem
sudo mkfs -t xfs $disk2
sleep 10

# Backup /etc/fstab
sudo cp /etc/fstab /etc/fstab-old

# Get the UUID of the partition and add it to /etc/fstab for permanent mounting
VUUID=$(sudo blkid -o value -s UUID $disk2)
sleep 10
sudo bash -c "echo 'UUID=$VUUID  /data   xfs   defaults        0       0' >> /etc/fstab"

# Mount all filesystems in /etc/fstab
sudo mount -a

# Change ownership of the /data directory to the current user
sudo chown -R $USER:$USER /data
echo "Disk mount complete"

# Navigate to the /data directory
cd /data    

# Reload shell environment
source ~/.bashrc

# Download the necessary files
wget https://raw.githubusercontent.com/ashu1211/java-tron/refs/heads/main/mainnet.conf
wget https://github.com/tronprotocol/java-tron/releases/download/GreatVoyage-v4.7.7/FullNode.jar

# Create the tron.service file
sudo bash -c 'cat <<EOL > /etc/systemd/system/tron.service
[Service]
Type=simple
User=root
Group=root
WorkingDirectory=/data
LimitNOFILE=16384
ExecStart=/usr/bin/java -Xmx28g -XX:+HeapDumpOnOutOfMemoryError -jar /data/FullNode.jar -c /data/mainnet.conf -d /data/output-directory
ExecReload=/bin/kill -s HUP 
Restart=always
RestartSec=5
LimitCORE=infinity
[Install]
WantedBy=multi-user.target
EOL'

# Start and enable the tron.service
sudo systemctl start tron.service
sudo systemctl enable tron.service

echo "Setup completed successfully!"
