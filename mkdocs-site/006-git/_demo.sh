#!/bin/bash

# Get the root folder of our demo folder
ROOT_FOLDER=$(git rev-parse --show-toplevel)

# Load the common script
source $ROOT_FOLDER/_utils/common.sh

# Spin up the docker containers
source $ROOT_FOLDER/Labs/000-setup/01-init-servers.sh
source $ROOT_FOLDER/Labs/000-setup/02-init-ansible.sh

# Copy the playbook to the scripts folder
cp *.yaml $RUNTIME_FOLDER/labs-scripts

# We will need to pre-install the missing plugin
# https://docs.ansible.com/ansible/latest/collections/community/general/git_config_module.html
# ansible-galaxy collection install community.general

# Install requirmens
docker exec ansible-controller sh -c "ansible-galaxy collection install community.general"

# run ansible playbook which installs git on the servers
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook ./006-playbook-install-git.yaml"
