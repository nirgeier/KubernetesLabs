#!/bin/bash

mkdir -p /labs-scripts/ansible
mkdir -p /labs-scripts/scripts

# unlock the user
echo "* Unlock root password"
passwd -u root

# Create the sshd_config
echo "* Generate sshd_config"
cat << EOF >> /etc/ssh/sshd_config
PasswordAuthentication  no
PermitRootLogin         yes
Port                    22
Protocol                2
EOF

# switch to the labs folder
cd /labs-scripts

# Start the ssh service
echo "* Start sshd service"
/usr/sbin/sshd -D &

echo "* Waiting for ssh service to start"
sleep 5

# This container will wait for input
sleep inf
