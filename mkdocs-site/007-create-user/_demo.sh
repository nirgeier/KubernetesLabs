#!/bin/bash

# Get the root folder of our demo folder
ROOT_FOLDER=$(git rev-parse --show-toplevel)

# Load the common script
source $ROOT_FOLDER/_utils/common.sh

# Get the current directory of our lab
CURRENT_DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
echo "Current directory $CURRENT_DIR"

# Spin up the docker containers
source $ROOT_FOLDER/Labs/000-setup/01-init-servers.sh
source $ROOT_FOLDER/Labs/000-setup/02-init-ansible.sh

# Copy the playbook to the scripts folder
cp *.yaml $RUNTIME_FOLDER/labs-scripts

# run ansible playbook which installs git on the servers
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook ./007-create-user.yaml"
