#!/bin/bash

# Get the root folder of our demo folder
ROOT_FOLDER=$(git rev-parse --show-toplevel)

# Load the common script
source $ROOT_FOLDER/_utils/common.sh

# Spin up the docker containers
source $ROOT_FOLDER/Labs/000-setup/01-init-servers.sh 2>&1 > /dev/null
source $ROOT_FOLDER/Labs/000-setup/02-init-ansible.sh 2>&1 > /dev/null

clear

# Install requirement
docker exec ansible-controller sh -c "ansible-galaxy collection install community.docker"

echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "* Copying the playbook to the scripts folder${COLOR_OFF}"
cp    *.yaml      $RUNTIME_FOLDER/labs-scripts
cp -r templates/  $RUNTIME_FOLDER/labs-scripts

tree -a $RUNTIME_FOLDER/labs-scripts

echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e ""
echo -e "* Executing ansible playbook"
echo -e ""
echo -e "${GREEN}$ cat 004-playbook.yaml ${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && cat 004-playbook.yaml"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e ""
echo -e "${GREEN}$ ansible-playbook 004-playbook.yaml ${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook 004-playbook.yaml"

echo -e ""
