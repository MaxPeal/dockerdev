#!/bin/bash

# Developer-oriented environment setup script
# -------------------------------------------
#
# Source this in your shell for the correct environment variables
#
# If you add a variable here, please check if it's set already and ignore it in that case

export COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-dev}"

# set up DOCKER_HOST automatically using docker-machine, if a DOCKER_MACHINE_NAME has been set
if [[ ${DOCKER_MACHINE_NAME:-} ]] && command -v docker-machine > /dev/null; then
  eval $(docker-machine env "${DOCKER_MACHINE_NAME}")
fi
