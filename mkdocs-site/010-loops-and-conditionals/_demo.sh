#!/bin/bash

clear

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

# Generate the playbook file
cat << EOF > $LABS_SCRIPT_FOLDER/010-loop-and-conditions.yaml
- hosts: linux-server-2
  tasks:
    - name: Run with items greater than 5
      ansible.builtin.command: echo {{ item }}
      loop: [ 0, 2, 4, 6, 8, 10 ]
      when: item > 5
EOF

# run ansible playbook which installs git on the servers
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook ./010-loop-and-conditions.yaml"

