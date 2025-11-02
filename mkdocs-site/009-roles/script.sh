#!/bin/bash

cd /labs-scripts

# Install ansible requiremens
ansible-galaxy collection install community.general

# Execute the playbook
ansible-playbook ./009-codewizard-role-playbook.yaml