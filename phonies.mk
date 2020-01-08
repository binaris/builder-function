ifndef __phonies_mk_included
__phonies_mk_included := true
unexport __phonies_mk_included

.PHONY: make_always
make_always: ;

.PHONY: require-tag
require-tag:
	@if [ -z $${tag+x} ]; then echo 'tag' make variable must be defined; false; fi

endif
