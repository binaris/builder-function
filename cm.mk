ifndef __cm_mk_included
__cm_mk_included := true
unexport __cm_mk_included

include $(MAKES)/phonies.mk
include $(MAKES)/aws.mk
include $(MAKES)/realm_config.mk

ansible_tags  := $(shell if [ "x$${quick}" = "xtrue" ]; then echo --tags app; fi)
ansible_check := $(shell if [ ! -z $${check+x} ]; then echo --check; fi)
ansible_ci    := -e ci=$(if $(CI),true,false)
ansible_branch ?= master

define common_ansible_options
	-e realm=$(realm)                           \
	-e region=$(region)                         \
	-e az=$(az)                                 \
	-e ansible_branch=$(ansible_branch)         \
	-e domain=$(domain)                         \
	-e account_id=$(account_id)                 \
	-e tag=$(tag)
endef

.PHONY: ec2.ini
ec2.ini: require-realm-envar require-tag
	jinja2 -D realm=$(realm) ec2.ini.j2 >ec2.ini

# realm_config is JSON.  Rather than escape it to pass as a shell
# argument, add it to the environment for Ansible.
export realm_config
.PHONY: $(SERVICES)
$(SERVICES): ec2.ini ~/.ssh/binaris-dev.pem
	@$(MAKES)/protect_important_realms.sh
	ansible-playbook                            \
		-i ec2.py                               \
		-l tag_service_$(subst -,_,$@)          \
		$(ansible_tags)                         \
		$(common_ansible_options)               \
		$(extra_ansible_options)                \
		$(ansible_ci)                           \
		-e service=$@                           \
		-e CONFIG_BASE=/opt/binaris             \
		-e domain=$(domain)                     \
		plays/$@.yml                            \
		$(ansible_check)

# runs on ASG instance on launch
bootstrap: my_role=$(shell ./get_ec2_tag.sh service)
bootstrap: my_id=$(shell curl http://169.254.169.254/latest/meta-data/instance-id)

.PHONY: bootstrap
bootstrap: require-tag require-realm-envar
	ansible-playbook                            \
	--private-key=/root/.ssh/id_rsa             \
	-i "localhost,"                             \
	-e service=$(my_role)                       \
	-e domain=$(domain)                         \
	-e CONFIG_BASE=/opt/binaris                 \
	-e bootstrap=true                           \
	-e ec2_region=$(region)                     \
	-e ec2_id=$(my_id)                          \
	$(ansible_tags)                             \
	-u root                                     \
	$(common_ansible_options)                   \
	$(extra_ansible_options)                    \
	-c smart plays/$(my_role).yml

HEALTHCHECKS := $(SERVICES:%=healthcheck-%)
.PHONY: $(HEALTHCHECKS)
$(HEALTHCHECKS): ec2.ini ~/.ssh/binaris-dev.pem
	ansible-playbook                                          \
		-l tag_service_$(subst -,_,$(subst healthcheck-,,$@)) \
		-i ec2.py                                             \
		$(common_ansible_options)                             \
		$(extra_ansible_options)                              \
		plays/health.yml

CM_RUNS := $(SERVICES:%=cm-run-%)
.PHONY: $(CM_RUNS)
$(CM_RUNS): ec2.ini ~/.ssh/binaris-dev.pem
	ansible-playbook                                     \
	    -l tag_service_$(subst -,_,$(subst cm-run-,,$@)) \
	    -i ec2.py                                        \
	    $(common_ansible_options)                        \
	    $(ansible_args)
endif
