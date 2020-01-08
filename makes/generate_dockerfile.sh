#!/bin/bash

set -euo pipefail
echo $@
DOCKER=$1
DOCKER_ACCOUNT=$2
INSTALLER_BASE_TAG=$3
TAG=$4
BRANCH_NAME=$5
TEMPLATE=$6

source "${BASH_SOURCE%/*}/github_branch_exists.sh"

if [[ "${INSTALLER_BASE_TAG}" = UNSPECIFIED ]]; then
    if (github_branch_exists installer-base "${BRANCH_NAME}"); then
        INSTALLER_BASE_TAG=${BRANCH_NAME}
    else
        INSTALLER_BASE_TAG=master
    fi
fi

if [[ "${TEMPLATE}" != "aether" ]] && [[ "${TEMPLATE}" != "installer-base" ]] && [[ "${TEMPLATE}" != "node-base" ]] && ! ${DOCKER} image inspect ${DOCKER_ACCOUNT}/installer-base:${INSTALLER_BASE_TAG} &> /dev/null; then
    echo "Missing installer base tag ${INSTALLER_BASE_TAG}"
    exit 1
fi

jinja2 --strict ${TEMPLATE}.Dockerfile.j2 \
    -D tag=${TAG} \
    -D installer_base_tag=${INSTALLER_BASE_TAG} \
    -D docker_account=${DOCKER_ACCOUNT} \
    > ${TEMPLATE}.Dockerfile < /dev/null
