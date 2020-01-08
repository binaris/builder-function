#!/bin/bash -eu

if [[ -f "/.dockerenv" ]]; then
    # we're running in a container, so TF version is probably not a problem
    exit 0
fi

realm_key=$1

tmp=$(mktemp)

if !(aws s3 cp --quiet s3://shared-tf-state.binaris/${realm_key} $tmp); then
    # Cannot find remote state file, nothing to worry about, probably a new deployment
    exit 0
fi

remote_version=$(cat $tmp | jq -r '.terraform_version')
local_version=$(terraform version | head -1 | grep -E -o "v[0-9.]+" | sed 's/v//')
rm $tmp


if [[ "$remote_version" != "$local_version" ]]; then
    echo "Your local terraform version does not match the remote one."
    echo "Local: $local_version"
    echo "Remote: $remote_version"

    read -p "Continue (y|n)? " -n 1 -r
    echo    # (optional) move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi

    exit 1
fi
