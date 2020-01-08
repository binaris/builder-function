ifndef __realm_config_mk_included
__realm_config_mk_included := true
unexport __realm_config_mk_included

include $(MAKES)/realm.mk

region     ?= $(shell echo $(realm_config_echo) | jq -r '.az[:-1]' 2>/dev/null)
az         ?= $(shell echo $(realm_config_echo) | jq -r '.az' 2>/dev/null)
realm_perf ?= $(shell echo $(realm_config_echo) | jq -r '.perf' 2>/dev/null)
realm_ha   ?= $(shell echo $(realm_config_echo) | jq -r '.ha' 2>/dev/null)
cost       ?= $(shell echo $(realm_config_echo) | jq -r '.cost' 2>/dev/null)
monitored  ?= $(shell echo $(realm_config_echo) | jq -r '.monitor' 2>/dev/null)

primaryDomain ?= $(shell echo $(realm_config_echo) | jq -r '.primaryDomain' 2>/dev/null)
apiSubdomain  ?= $(shell echo $(realm_config_echo) | jq -r '.apiSubdomain' 2>/dev/null)
runDomain     ?= $(shell echo $(realm_config_echo) | jq -r '.runDomain' 2>/dev/null)

storageCDNApexDomain ?= $(shell echo $(realm_config_echo) | jq -r '.storageCDNApexDomain' 2>/dev/null)
storageCDNPrimaryDomain ?= $(shell echo $(realm_config_echo) | jq -r '.storageCDNPrimaryDomain' 2>/dev/null)

ifeq ($(realm),prod)
	apiDomain ?= $(apiSubdomain).$(primaryDomain)
else
	apiDomain ?= $(apiSubdomain)-$(realm).$(primaryDomain)
endif
apiUrl ?= https://$(apiDomain)

ifeq ($(realm),prod)
	webappDomain ?= $(primaryDomain)
else
	webappDomain ?= $(realm).$(primaryDomain)
endif
webappUrl ?= https://$(webappDomain)

ifeq ($(realm),prod)
	storageCDNDomain ?= $(storageCDNPrimaryDomain)
else
	storageCDNDomain ?= $(realm).$(storageCDNPrimaryDomain)
endif

endif
