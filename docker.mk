ifndef __docker_mk_included
__docker_mk_included := true
unexport __docker_mk_included

include $(MAKES)/git.mk
include $(MAKES)/aws.mk
include $(MAKES)/phonies.mk

ECR := $(account_id).dkr.ecr.us-east-1.amazonaws.com
export ECR

ifneq ($(strip $(TRIGGER_BRANCH)),)
INTEGRATION_BRANCH := $(TRIGGER_BRANCH)
else
ifneq ($(strip $(BRANCH_NAME)),)
INTEGRATION_BRANCH := $(BRANCH_NAME)
else
INTEGRATION_BRANCH := $(BRANCH)
endif
endif

# rebuild is slower, does not use docker cache, to avoid the apt-get DNS failures. See https://stackoverflow.com/q/24991136/51197
NO_CACHE = $(shell if [ $${NO_CACHE:-false} != false ]; then echo --no-cache; fi)
SUDO := $(shell if docker info 2>&1 | grep "permission denied" >/dev/null; then echo "sudo -E"; fi)
INTERACTIVE := $(shell if [ -t 0 ]; then echo "-it"; fi)
DOCKER := $(SUDO) docker
export DOCKER

DOCKERFILES: $(foreach image,$(DOCKER_IMAGES),$(image).Dockerfile)

IS_JENKINS := $(shell if [ "$$JENKINS_URL" ]; then echo true; fi)

# TODO(michael): drop binaris as DOCKER_ACCOUNT
DOCKER_ACCOUNT := $(if $(IS_JENKINS),$(ECR),binaris)

installer_base_tag ?= $(tag)

%.Dockerfile: %.Dockerfile.j2 make_always require-tag
	$(MAKES)/generate_dockerfile.sh "$(DOCKER)" "$(DOCKER_ACCOUNT)" "$(installer_base_tag)" "$(tag)" "$(BRANCH_NAME)" "$*"

PUSHED_IMAGES = $(filter-out $(IMAGES_NOT_PUSHED),$(DOCKER_IMAGES))

INSTALL_IMAGES := $(foreach image,$(INSTALLER_IMAGES),install-$(image))
$(INSTALL_IMAGES): make_always

BUILD_IMAGES := $(foreach image,$(DOCKER_IMAGES),build-$(image))
$(BUILD_IMAGES): make_always

.PHONY: build rebuild
rebuild build: $(BUILD_IMAGES) $(INSTALL_IMAGES)

$(DOCKER_IMAGES): %: build-%

PUSH_IMAGES := $(foreach image,$(PUSHED_IMAGES),push-$(image)) $(foreach image,$(INSTALLER_IMAGES),push-$(image)-installer)
$(PUSH_IMAGES): make_always

NPM_RC := $(if $(IS_JENKINS),.npmrc,~/.npmrc)
NPM_TOKEN := $(shell cat $(NPM_RC) | cut -d "=" -f 2)
rebuild: NO_CACHE=--no-cache
build-%: %.Dockerfile require-tag
	@$(DOCKER) build $(NO_CACHE) --label GIT_COMMIT=$(COMMIT) --build-arg NPM_TOKEN=$(NPM_TOKEN) -t binaris/$*:$(tag) -f $*.Dockerfile .
	$(MAKES)/tag_image.sh "$(DOCKER)" $* $(tag) $(INTEGRATION_BRANCH) $(ECR)


install-%: %.installer.Dockerfile require-tag
	$(DOCKER) build $(NO_CACHE) --label GIT_COMMIT=$(COMMIT) -t binaris/$*-installer:$(tag) -f $*.installer.Dockerfile .
	$(MAKES)/tag_image.sh "$(DOCKER)" $*-installer $(tag) $(INTEGRATION_BRANCH) $(ECR)

push-%: ecr require-tag
	@echo pushing explicit tag $(tag)
	$(DOCKER) push $(ECR)/$*:$(tag)
ifeq ($(IS_JENKINS),true)
	@echo pushing integration branch tag $(INTEGRATION_BRANCH)
	$(DOCKER) push $(ECR)/$*:$(INTEGRATION_BRANCH)
endif

.PHONY: push
push: $(PUSH_IMAGES)

.PHONY: ecr
ecr:
	$(SUDO) `aws ecr get-login --no-include-email --region us-east-1`

endif
