ifndef __tf_mk_included
__tf_mk_included := true
unexport __tf_mk_included

# THIS LINE MUST APPEAR ABOVE ALL INCLUDES!
#
# GNU Make `include' keeps all Makefiles loaded in $(MAKEFILE_LIST).
# So the last word is the path to this Makefile, until the first
# include.
THIS_TF_DIR := $(dir $(lastword $(MAKEFILE_LIST)))

include $(MAKES)/phonies.mk
include $(MAKES)/realm.mk
include $(MAKES)/aws.mk
include $(MAKES)/realm_config.mk

# Parent directory of *all* .tf.j2 files.  If not set,
TF_DIR ?= $(THIS_TF_DIR)/..
TF ?= ../terraform
TF_FLAVORS ?= ../flavors
TF_PLAN_DIR ?= .

terrajinja := $(shell find $(TF_DIR) -name "*.tf.j2")
terraauto := $(patsubst %.tf.j2, %.auto.tf, $(terrajinja))

ansible_branch ?= master

tf_no_color = $(shell if [ ! -z $${NO_COLOR+x} ]; then echo -no-color; fi)

COMMON_TF_VARS := -var "realm=$(realm)"                       \
    -var "realm_ha=$(realm_ha)"                               \
    -var "realm_perf=$(realm_perf)"                           \
    -var "region=$(region)"                                   \
    -var "az=$(az)"                                           \
    -var "domain=$(domain)"                                   \
    -var "primaryDomain=$(primaryDomain)"                     \
    -var "apiSubdomain=$(apiSubdomain)"                       \
    -var "apiDomain=$(apiDomain)"                             \
    -var "webappDomain=$(webappDomain)"                       \
    -var "storageCDNApexDomain=$(storageCDNApexDomain)"       \
    -var "storageCDNPrimaryDomain=$(storageCDNPrimaryDomain)" \
    -var "storageCDNDomain=$(storageCDNDomain)"               \
    -var "monitored=$(monitored)"                             \
    -var 'DONT_CALL_TERRAFORM_DIRECTLY=1'                     \
    -var 'ansible_branch=$(ansible_branch)'                   \
    -var 'tag=$(tag)'                                         \
    -var 'cost=$(cost)'                                       \
    $(tf_no_color)                                            \
    -var-file "$(TF_FLAVORS)/realm_perf_$(realm_perf).tfvars" \
    -var-file "$(TF_FLAVORS)/realm_ha_$(realm_ha).tfvars"     \
    $(TF_PLAN_DIR)

%.auto.tf: make_always require-realm-envar
	@echo Jinja compiling $@
	@jinja2 $*.tf.j2 \
		-D realm_ha=$(realm_ha) \
		-D realm_perf=$(realm_perf) \
		-D monitored=$(monitored) \
		-D cost=$(cost) \
		>$@

.PHONY: jinja
jinja: $(terraauto)

.PHONY: plan
plan: get
	$(TF) plan $(EXTRA_TF_VARS) $(COMMON_TF_VARS)

.PHONY: plan-destroy
plan-destroy: get state
	$(TF) plan -destroy $(EXTRA_TF_VARS) $(COMMON_TF_VARS)

.PHONY: clean_state
clean_state:
	rm -rf .terraform

.PHONY: clean_all_state
clean_all_state:
	rm -rf .terraform*

.terraform.$(realm):
	mkdir -p .terraform.$(realm)

.PHONY: state
state: .terraform init

.PHONY: .terraform
.terraform: .terraform.$(realm) clean_state require-realm-envar
	ln -s .terraform.$(realm) .terraform

.PHONY: init
init: init_backend

SHELL := /bin/bash

.PHONY: init_backend
init_backend: require-realm-envar jinja
	if [[ -z "$$state_s3_key" ]]; then echo "state_s3_key not defined"; exit 1; fi
	$(MAKES)/check_tf_version.sh "$(state_s3_key)"
	cd $(TF_PLAN_DIR); $(TF) init -force-copy -backend-config="key=$(state_s3_key)" -backend=true

.PHONY: apply
apply: get
	@$(MAKES)/protect_important_realms.sh
	$(TF) apply -auto-approve $(EXTRA_TF_VARS) $(COMMON_TF_VARS)

.PHONY: validate
validate: get
	$(TF) validate $(TF_PLAN_DIR)

.PHONY: get
get: state
	$(TF) get $(TF_PLAN_DIR)

destroy: state
	$(MAKES)/protect_important_realms.sh
	$(TF) destroy -force $(EXTRA_TF_VARS) $(COMMON_TF_VARS)

.PHONY: output
output: state
	$(TF) output

%-output.json: state
	$(TF) output -json > $@

.PHONY: refresh
refresh: state
	$(TF) refresh $(EXTRA_TF_VARS) $(COMMON_TF_VARS)

.PHONY: unlock
unlock: state
	@read -p "Enter Lock ID: " LOCK; $(TF) force-unlock $$LOCK

.PHONY: graph
graph: state
	$(TF) graph | dot -Tpng > $(TMP_PNG)
	open $(TMP_PNG)

.PHONY: list
list: state
	$(TF) state list

.PHONY: taint
taint: state
	$(TF) taint $(VICTIM)

TMP_PNG := $(shell mktemp).png

endif # include guard
