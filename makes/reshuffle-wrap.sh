#!/bin/bash -eu
echo Reshuffle Wrapping ${1}
export RESHUFFLE_API_ENDPOINT=${apiUrl}/public/v1
export RESHUFFLE_WEBAPP_LOGIN_URL=${webappUrl}/cli-login
if [[ ! -z "${RESHUFFLE_ACCESS_TOKEN+x}" ]]; then
	export RESHUFFLE_CONFIG=$(mktemp /tmp/reshuffle.yml.XXXXXXXX)
	echo "accessToken: ${RESHUFFLE_ACCESS_TOKEN}" > ${RESHUFFLE_CONFIG}
fi

${1}

if [[ ! -z "${RESHUFFLE_ACCESS_TOKEN+x}" ]]; then
	unlink ${RESHUFFLE_CONFIG}
fi
