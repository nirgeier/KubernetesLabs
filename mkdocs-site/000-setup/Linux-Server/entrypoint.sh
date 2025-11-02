#!/bin/bash

# 
# This script will create the required keys for the ansible playground
# We will connect to this continuer using ssh key
#
function create_ssh_key_file(){
    # Check to see if we have certificate
    echo "* Creating SSH key for $HOSTNAME [$ssh_key_file]"
    ssh-keygen -R $HOSTNAME
    ssh-keygen -t rsa -q -P '' -f $ssh_key_file <<<y
}

# Verify that we have the desired folder
mkdir -p    /root/.ssh

# Verify the authorized_keys for first use
echo "* Verify the existence of authorized_keys"
touch       /root/.ssh/authorized_keys

# The ssh file we looking for
ssh_key_file=/root/.ssh/$HOSTNAME

# Check to see if we have certificate
create_ssh_key_file

# echo "* Add keys to authorized_keys"
chmod 777 /root/.ssh/authorized_keys

# Add the key to the authorized_keys
# On the "server" we are adding the trusted key to the authorized_keys
echo "* Add key to authorized_keys"
cat ${ssh_key_file}.pub >> /root/.ssh/authorized_keys

# Set the required flags 
chmod 600 /root/.ssh/authorized_keys  

# Create the sshd_config
echo "* Generate sshd_config"
cat << EOF > /etc/ssh/sshd_config
PasswordAuthentication  no
PermitRootLogin         yes
Port                    22
Protocol                2
EOF

# Start the ssh service
echo "* Start sshd service"
/usr/sbin/sshd -D &

echo "* Waiting for ssh service to start"
sleep 10

# Check if SSH is running
# We will try for 5 times at most
for i in {1..5}
do
    # Try to connect with ssh 
    ssh -v -i ~/.ssh/$HOSTNAME -o StrictHostKeyChecking=accept-new root@localhost
    # Verify that ssh is running, if not restart it and retry
    if [[ "$?" -eq 0 ]]; 
    then
        # Exit the white loop
        echo "SSH is running."
        break
    else
        # Wait for the service to start
        echo "SSH is not running. Retrying..."
        create_ssh_key_file
        /usr/sbin/sshd -D &
        sleep 5
    fi
done

# Continue with other commands if any
exec "$@"

# Keep the container in idle mode
sleep infinity