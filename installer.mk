ifndef __installer_mk_included
__installer_mk_included := true
unexport __installer_mk_included

include $(MAKES)/phonies.mk
include $(MAKES)/docker.mk

FORWARDED_TF_COMMANDS := apply plan destroy graph unlock refresh list taint plan-destroy output-json
FORWARDED_COMMANDS := $(FORWARDED_TF_COMMANDS) play healthcheck

# This is a macro which generates terraform rules per service per command
# (such as apply-zuul or plan-marathon-redis or unlock-function-store)
# $1 is the terraform command (such as `apply`)
# $2 is the installer image (such as `zuul`)
define CREATE_TF_RULE
.PHONY: $1-$2
$1-$2: make_always install-$2
	$(SUDO) $(MAKES)/installer.sh $2 bash -c "make -C tf $1"
endef

# Loop on all services with installer and all terraform command to generate appropriate rules
$(foreach service,$(INSTALLER_IMAGES),$(foreach command,$(FORWARDED_TF_COMMANDS),$(eval $(call CREATE_TF_RULE,$(command),$(service)))))

# There is only one ansible command (`play`) so we can just create play-install-image targets directly
PLAY_INSTALLER_IMAGES := $(INSTALLER_IMAGES:%=play-%)
CHECK_INSTALLER_IMAGES := $(INSTALLER_IMAGES:%=healthcheck-%)

# And the general play rule is simple,
.PHONY: $(PLAY_INSTALLER_IMAGES)
$(PLAY_INSTALLER_IMAGES): play-%: install-% require-realm-envar
	$(SUDO) $(MAKES)/installer.sh $* bash -c "cd cm; make $*"

.PHONY: $(CHECK_INSTALLER_IMAGES)
$(CHECK_INSTALLER_IMAGES): healthcheck-%: require-realm-envar
	$(SUDO) $(MAKES)/installer.sh $* bash -c "cd cm; make healthcheck-$*"

# Each forwarded command depends on that command of all the installer images
.PHONY: $(FORWARDED_COMMANDS)
$(FORWARDED_COMMANDS): %: $(addprefix %-,$(INSTALLER_IMAGES))

$(INSTALL_IMAGES): install-%: %.installer.Makefile

INSTALLER_MAKEFILES := $(INSTALLER_IMAGES:%=%.installer.Makefile)

$(INSTALLER_MAKEFILES): %.installer.Makefile: makes/installer.Makefile.j2
	jinja2 -D service="$*" $< >$@

endif
