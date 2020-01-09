ifndef __git_mk_included
__git_mk_included := true
unexport __git_mk_included

BRANCH := $(shell if [[ ! -z $${BRANCH_NAME+x} ]]; then echo $${BRANCH_NAME}; else git rev-parse --abbrev-ref HEAD 2>/dev/null || echo UNKNOWN; fi)

# On some machines there's no .git dir, just the working copy. In these
# cases, don't fail the build, but make it clear it's not to be considered
# a stable one.
COMMIT := $(shell git rev-parse HEAD 2>/dev/null || echo UNSTABLE)

endif
