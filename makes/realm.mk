ifndef __realm_mk_included
__realm_mk_included := true
unexport __realm_mk_included

# This is a lambda function that fetches the json config file for a given realm.
# See the realms repo for more info.
realm_config := $(shell curl \
	--connect-timeout 5 \
	--max-time 3 \
	--retry 5 \
	--retry-max-time 30 \
	--fail \
	--location \
	--silent \
	--show-error \
	https://ci8gxmviyd.execute-api.us-east-1.amazonaws.com/dev/fetch/$(realm) 2>/dev/null)
realm_config_echo := '$(subst ','"'"',$(realm_config))'
domain ?= $(shell echo $(realm_config_echo) | jq -r '.domain' 2>/dev/null)
domain := $(domain)
export domain

# Check realm config by looking up region
__check_config := $(shell echo $(realm_config_echo) | jq -r '.region' 2>/dev/null | grep -v -E '^$$' >/dev/null; echo $$?)
.PHONY: require-realm-envar
require-realm-envar:
ifndef realm
	$(error 'realm' environment variable must be defined)
endif
ifneq ($(__check_config),0)
	$(error Failed fetching config for realm $(realm), $(realm_config))
endif
unexport __check_config

endif # __realm_mk_included
