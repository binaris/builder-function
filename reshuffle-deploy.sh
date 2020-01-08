#!/bin/bash -eux
set -o pipefail

deployedAppName=$(${reshuffle} list --format json | jq -r ".[] | select(.name == \"${appName}\") | .name")
if [[ -n ${deployedAppName} ]]; then
    deployArgs="--app-name=$appName"
else
    deployArgs="--new-app"
fi
newAppName=$(${reshuffle} deploy ${deployArgs} | grep 'Your project is now available at: https://([^.]*)' -o -E | sed 's#Your project is now available at: https://##')

if [[ -z ${deployedAppName} ]]; then
    ${reshuffle} rename -s=${newAppName} ${appName}
fi
