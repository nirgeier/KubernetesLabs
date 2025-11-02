###
### Base images for Ansible Controller
### @Author: Nir Geier
### 
FROM  ubuntu 

# Update packages, install OpenSSH
RUN                                   \
  apt update  -o Acquire::http::Timeout=5 -y &&                   \
  apt upgrade -o Acquire::http::Timeout=5 -y &&                   \
  apt --purge autoremove -y                  &&                   \
  apt install -y software-properties-common openssh-server vim && \
  apt-add-repository ppa:ansible/ansible     &&                   \
  apt install -y ansible

# This directory is required by the SSH daemon to store its temporary runtime data.  
RUN   mkdir -p /var/run/sshd

# We will need to use ssh
EXPOSE  22 

# Copy the entrypoint script
# Generate keys when container is created
COPY    entrypoint.sh   /entrypoint.sh
RUN     chmod +x        /entrypoint.sh

USER    root

###
### Debug
###
RUN apt install -y inetutils-ping

# Run the loading script
ENTRYPOINT      ["/entrypoint.sh"]

