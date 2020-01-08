#!/bin/bash -ex

DOCKER=$1
IMAGE=$2
tag=$3
INTEGRATION_BRANCH=$4
ECR=$5


if [[ "$JENKINS_URL" ]]; then
    $DOCKER tag binaris/$IMAGE:$tag binaris/$IMAGE:$INTEGRATION_BRANCH
    $DOCKER tag binaris/$IMAGE:$tag $ECR/$IMAGE:$INTEGRATION_BRANCH
fi
$DOCKER tag binaris/$IMAGE:$tag $ECR/$IMAGE:$tag
$DOCKER tag binaris/$IMAGE:$tag $IMAGE
