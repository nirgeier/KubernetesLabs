#!/bin/bash

# Get the root folder of our demo folder
ROOT_FOLDER=$(git rev-parse --show-toplevel)

# Set the root folder for the demo
echo "ROOT_FOLDER=$ROOT_FOLDER" > .env

# Spin up the docker containers
source $ROOT_FOLDER/Labs/000-setup/00-build-containers.sh
source $ROOT_FOLDER/Labs/000-setup/01-init-servers.sh
source $ROOT_FOLDER/Labs/000-setup/02-init-ansible.sh
