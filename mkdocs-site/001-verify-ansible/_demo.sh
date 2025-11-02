#!/bin/bash

###
### Check the servers with simple ansible configuration
###

# Get the root folder of our demo folder
ROOT_FOLDER=$(git rev-parse --show-toplevel)

# Load the common script
source $ROOT_FOLDER/_utils/common.sh

# Spin up the docker containers
source $ROOT_FOLDER/Labs/000-setup/01-init-servers.sh 2>&1 > /dev/null
source $ROOT_FOLDER/Labs/000-setup/02-init-ansible.sh 2>&1 > /dev/null

echo -e "${YELLOW} ----------------------------------------------------------------------${COLOR_OFF}"
echo -e ""
echo -e "${CYAN}* Check ansible configuration ${COLOR_OFF}"
docker exec ansible-controller ansible --version

echo -e "${YELLOW}----------------------------------------------------------------------${COLOR_OFF}"
echo -e ""
echo -e "${CYAN}* Check the setup, execute a basic ansible script${COLOR_OFF}"
echo -e "${GREEN}* Executing: ${YELLOW}ansible all -m ping${COLOR_OFF}"
# Test that the servers can accept connections from the ansible server
docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m ping"