#!/bin/bash -ex
set -u
export service=$1
shift

export image=${installer_image:-${service}-installer}

# Please note the loop here is similar
# to aether/terraform/modules/asg/installer-bootstrap.sh
# on purpose.
export TRIES=${MAX_TRIES:-1}

sleep_or_exit() {
    s=$?
    if [ "$1" -lt "$TRIES" ]; then
        sleep ${RETRY_INTERVAL_S:-15}
    else
        exit $s
    fi
}

export HOST_BINARIS_DEV_PEM=${HOME}/.ssh/binaris-dev.pem

for i in $(seq 1 $TRIES); do
	(docker run ${docker_run_args:-}                         \
		-e AWS_ACCESS_KEY_ID                                 \
		-e AWS_SECRET_ACCESS_KEY                             \
		-e check                                             \
		-e domain                                            \
		-e HOST_BINARIS_DEV_PEM                              \
		-e force                                             \
		-e realm                                             \
		-e realm_ha                                          \
		-e realm_perf                                        \
		-e region                                            \
		-e quick                                             \
		-e state_s3_key                                      \
		-e tag                                               \
		-e service                                           \
		-e TF_LOG                                            \
		-e TF_PLAN_DIR                                       \
		-e VICTIM                                            \
        --init                                               \
        ${INTERACTIVE:-}                                     \
		-v ${HOST_BINARIS_DEV_PEM}:/root/.ssh/binaris-dev.pem\
        --rm ${ECR}/${image}:${tag} "$@")        \
        && break || sleep_or_exit $i;
done
