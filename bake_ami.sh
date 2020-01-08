#!/bin/bash

set -euo pipefail

echo "Bake AMI for $service in $ami_region, storage: $mount_scheme, installer version: $installer_version, service version: $service_version"

if [[ "$mount_scheme" = "nvme" ]]; then
    export instance_type="m5.xlarge"
else
    echo Invalid mount_scheme: $mount_scheme 1>&2
    exit 1
fi

function ami_missing() {
    aws --region ${ami_region} ec2 describe-images --owners 660172796682 --filters "Name=name,Values=$1-*" | jq '.Images | length == 0'
}

if $(ami_missing "baked-${service}-${mount_scheme}-${installer_version}-${service_version}"); then
    if $(ami_missing "baked-${service}-${mount_scheme}-${installer_version}"); then
        echo Building AMI from base image
        packer build packer.json
    else
        echo Updating AMI with correct service docker image
        packer build -var quick=true -var source_ami_filter=baked-${service}-${mount_scheme}-${installer_version}-* packer.json
    fi
else
    echo AMI with correct installer and service docker image already built, nothing to do
fi

