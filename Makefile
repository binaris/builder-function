SHELL := /bin/bash
MAKES := makes

include $(MAKES)/git.mk
include $(MAKES)/realm.mk
include $(MAKES)/realm_config.mk

DOCKER_IMAGES := builder-function

.DEFAULT_GOAL := build-builder-function

include $(MAKES)/docker.mk
include $(MAKES)/installer.mk
include $(MAKES)/npm.mk

DOCKER_RUN_BASE := $(DOCKER) run --rm --init $(DOCKERARGS)
ifeq ($(INTERACTIVE), -it)
DOCKER_RUN := $(DOCKER_RUN_BASE) $(INTERACTIVE) -e LOG_PRETTY=true
else
DOCKER_RUN := $(DOCKER_RUN_BASE)
endif
IMAGE := $(ECR)/builder-function:$(tag)

NPM_COMMANDS = test lint
.PHONY: $(NPM_COMMANDS)

$(NPM_COMMANDS): require-tag
	$(DOCKER_RUN) $(IMAGE) bash -c "npm run $@"

reshuffle ?= npx reshuffle
export reshuffle
export apiUrl
export webappUrl

export appName=builder-function

.PHONY: reshuffle-play
reshuffle-play: require-realm-envar
	$(MAKES)/reshuffle-wrap.sh ./reshuffle-deploy.sh

.PHONY: reshuffle-destroy
reshuffle-destroy: require-realm-envar
	$(MAKES)/reshuffle-wrap.sh ./reshuffle-destroy.sh
