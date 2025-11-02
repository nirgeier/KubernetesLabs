#!/bin/bash

clear

# Get the root folder of our demo folder
ROOT_FOLDER=$(git rev-parse --show-toplevel)
export ROOT_FOLDER=$ROOT_FOLDER

# Load the common script
source $ROOT_FOLDER/_utils/common.sh

# Get the current directory of our lab
CURRENT_DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)

# Get the root folder of our demo folder
echo "ROOT_FOLDER=$ROOT_FOLDER"          > $CURRENT_DIR/.env
echo "RUNTIME_FOLDER=$RUNTIME_FOLDER"   >> $CURRENT_DIR/.env
echo "CURRENT_DIR=$CURRENT_DIR"         >> $CURRENT_DIR/.env

# Set the docker image platform we will need to use

# Generate .env
TARGET_PLATFORM=$(detect_platform)
echo "TARGET_PLATFORM=$TARGET_PLATFORM" >> $CURRENT_DIR/.env

# check if any running containers
if [ $(docker ps -aq | wc -l) -gt 1 ]; then
    # Remove all docker-container
    echo -e "${YELLOW}Removing old docker containers${COLOR_OFF}"
    docker stop $(docker ps -aq)
    docker rm   $(docker ps -aq)

    # Stop any existing demo containers
    docker_compose -f $CURRENT_DIR/docker-compose.yaml down
    sleep 5
fi

echo -e "${YELLOW}* Removing old content${COLOR_OFF}"
rm -rf $RUNTIME_FOLDER

echo -e "${YELLOW}* Creating folder structure${COLOR_OFF}"
mkdir -p $RUNTIME_FOLDER/.ssh
mkdir -p $RUNTIME_FOLDER/.ssh-server
mkdir -p $RUNTIME_FOLDER/labs-scripts

# Start the demo containers
echo -e "${GREEN}* Starting docker containers${COLOR_OFF}"
docker_compose -f $CURRENT_DIR/docker-compose.yaml up --build
sleep 5

# Sleep for few seconds so the entrypoint will finish its running
echo -e "${YELLOW}* Sleeping 5 seconds - waiting for container to start ${COLOR_OFF}"
echo -e ""

for i in {1..10}; 
do  
    echo -e -n "${RED}." 
    sleep 1
done

docker ps --format "table {{.ID}}\t{{.Image}}\t{{.Status}}"
sleep 3