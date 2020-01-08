ifndef __aws_mk_included
__aws_mk_included := true
unexport __aws_mk_included

SHELL := /bin/bash
include $(MAKES)/realm.mk

account_id := 660172796682

~/.ssh/binaris-dev.pem:
	$(MAKES)/install_dev_key.sh

# If you're getting error here on Mac, make sure you have Make version 4.00 or up
ifneq ("$(wildcard ~/.aws/credentials)","")
  AWS_ACCESS_KEY_ID      ?=  $(shell aws configure get aws_access_key_id)
  AWS_SECRET_ACCESS_KEY  ?=  $(shell aws configure get aws_secret_access_key)
  export AWS_ACCESS_KEY_ID
  export AWS_SECRET_ACCESS_KEY
endif

endif # __aws_mk_included
