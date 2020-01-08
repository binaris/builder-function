#!/bin/bash -eux
set -o pipefail

deployedAppName=$(${reshuffle} list --format json | jq -r ".[] | select(.name == \"${appName}\") | .name")
if [[ -n ${deployedAppName} ]]; then
    ${reshuffle} destroy ${deployedAppName}
fi
