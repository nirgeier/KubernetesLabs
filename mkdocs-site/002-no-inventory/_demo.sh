#!/bin/bash

# Get the root folder of our demo folder
ROOT_FOLDER=$(git rev-parse --show-toplevel)

# Load the common script
source $ROOT_FOLDER/_utils/common.sh

# Spin up the docker containers
source $ROOT_FOLDER/Labs/000-setup/01-init-servers.sh 2>&1 > /dev/null
source $ROOT_FOLDER/Labs/000-setup/02-init-ansible.sh 2>&1 > /dev/null

# Empty the inventory file so that no server is listening
echo -e "${CYAN}* Creating $RUNTIME_FOLDER/labs-scripts/inventory"
cat <<EOF > $RUNTIME_FOLDER/labs-scripts/inventory
###
### Empty inventory file
###

[servers]
EOF

echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${Red}* Our inventory file:${COLOR_OFF}"
cat $RUNTIME_FOLDER/labs-scripts/inventory

echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${Red}* Ansible should fail. No inventory file used${COLOR_OFF}"
echo -e "${GREEN}* Executing: ${YELLOW}ansible all -m ping${COLOR_OFF}"
# The script should fail
docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m ping"


