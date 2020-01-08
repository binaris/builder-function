ifndef __npm_mk_included
__npm_mk_included := true
unexport __npm_mk_included

include $(MAKES)/phonies.mk
include $(MAKES)/docker.mk
include $(MAKES)/git.mk

$(DOCKER_IMAGES): %: npm-publish-% npm-prepublish-% concord-publish-koa-server-% concord-publish-node-client-%

.PHONY: require-npm-token
require-npm-token:
ifndef NPM_TOKEN
	$(error 'NPM_TOKEN' not available)
endif

.PHONY: require-npm-tag
require-npm-tag:
	@if [ -z $${NPM_TAG+x} ]; then echo 'NPM_TAG' make variable must be defined; false; fi

npm-prepublish-% npm-publish-%: require-npm-tag require-tag require-npm-token make_always build-%
	$(DOCKER) run --rm binaris/$*:$(tag) bash -c "grep '\"name\": \"@binaris/' package.json >/dev/null || (echo package name must be scoped with @binaris && false)"
	$(DOCKER) run --rm binaris/$*:$(tag) \
		bash -c 'echo "//registry.npmjs.org/:_authToken=$(NPM_TOKEN)">~/.npmrc && \
			npm publish $(NPM_TAG) && \
			rm ~/.npmrc'

npm-prepublish-%: NPM_TAG?=--tag $(BRANCH)

concord-publish-koa-server-%: require-npm-tag require-tag require-npm-token make_always build-%
	$(DOCKER) run --rm $(ECR)/$*:$(tag) bash -c "grep '\"name\": \"@binaris/' interfaces/package.json >/dev/null || (echo package name must be scoped with @binaris && false)"
	$(DOCKER) run --rm $(ECR)/$*:$(tag) \
		bash -c 'echo "//registry.npmjs.org/:_authToken=$(NPM_TOKEN)">~/.npmrc && \
			cd interfaces && npm start "publishKoaServer -t $(NPM_TAG)"'

concord-publish-node-client-%: require-npm-tag require-tag require-npm-token make_always build-%
	$(DOCKER) run --rm $(ECR)/$*:$(tag) bash -c "grep '\"name\": \"@binaris/' interfaces/package.json >/dev/null || (echo package name must be scoped with @binaris && false)"
	$(DOCKER) run --rm $(ECR)/$*:$(tag) \
		bash -c 'echo "//registry.npmjs.org/:_authToken=$(NPM_TOKEN)">~/.npmrc && \
			cd interfaces && npm start "publishNodeClient -t $(NPM_TAG)"'

concord-publish-browser-client-%: require-npm-tag require-tag require-npm-token make_always build-%
	$(DOCKER) run --rm $(ECR)/$*:$(tag) bash -c "grep '\"name\": \"@binaris/' interfaces/package.json >/dev/null || (echo package name must be scoped with @binaris && false)"
	$(DOCKER) run --rm $(ECR)/$*:$(tag) \
		bash -c 'echo "//registry.npmjs.org/:_authToken=$(NPM_TOKEN)">~/.npmrc && \
			cd interfaces && npm start "publishBrowserClient -t $(NPM_TAG)"'

endif # __npm_mk_included
