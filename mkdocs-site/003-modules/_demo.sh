#!/bin/bash

# Get the root folder of our demo folder
ROOT_FOLDER=$(git rev-parse --show-toplevel)

# Load the common script
source $ROOT_FOLDER/_utils/common.sh

# Spin up the docker containers
source $ROOT_FOLDER/Labs/000-setup/01-init-servers.sh 2>&1 > /dev/null
source $ROOT_FOLDER/Labs/000-setup/02-init-ansible.sh 2>&1 > /dev/null

echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${Red}* Our inventory file:${COLOR_OFF}"
cat $RUNTIME_FOLDER/labs-scripts/inventory

echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${GREEN}* Executing: ${YELLOW}ansible all -m ping${COLOR_OFF}"

# Execute the different modules

echo -e ""
echo -e "${YELLOW}[ansible all -m ping] -----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m ping"

echo -e ""
echo -e "${YELLOW}[ansible all -m shell -a 'hostname'] -----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m shell -a 'hostname'"

echo -e ""
echo -e "${YELLOW}[ansible linux-server-1 -m shell -a 'uname -a'] -----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible linux-server-1 -m shell -a 'uname -a'"

