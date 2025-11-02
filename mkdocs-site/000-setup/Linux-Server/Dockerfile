###
### Ansible server based upon ubuntu
### @Author: Nir Geier
### 
FROM  ubuntu

# Update packages, install OpenSSH
RUN                                   \
  apt update      &&                  \
  apt upgrade -y  &&                  \
  apt-get install -y openssh-server vim

# This directory is required by the SSH daemon to store its temporary runtime data.  
RUN   mkdir -p /var/run/sshd
RUN   mkdir -p /root/.ssh

# We will need to use ssh
EXPOSE  22 

# Add healthcheck
HEALTHCHECK           \
  --interval=10s      \
  --timeout=10s       \
  --start-period=10s  \
  --retries=10         \
  CMD                                 \
  ssh -i ~/.ssh/$HOSTNAME             \
  -o StrictHostKeyChecking=accept-new \
  root@localhost                      \
  exit

# Copy the entrypoint script
# Generate keys when container is created
COPY    entrypoint.sh   /entrypoint.sh
RUN     chmod +x        /entrypoint.sh

USER    root

# Run the loading script
ENTRYPOINT      ["/entrypoint.sh"]



