# Shell sets the default behaviour for all shell functions running in the makefiles
SHELL := /bin/bash
HOME := $(shell git rev-parse --show-toplevel)
# These are used for the helm release name (to uninstall and install and put inplace the mesh identity configmap)
YQCMD := docker run -i docker.greymatter.io/internal/yq:2.4.1
CUST := $(shell cat $(HOME)/global.yaml | $(YQCMD) -r '.global.release.customer' )
RAND := $(shell kubectl get configmap greymatter-mesh-identity-$(CUST) -o jsonpath='{.data.rand_identifier}' 2> /dev/null )

# Colors
ccred := $(shell echo '\033[0;31m')
ccyellow := $(shell echo '\033[0;33m')
ccend := $(shell echo '\033[0m')

# Service account creation is set to true by default and this automates the disableing of these in makefiles
WSA_CHECK := $(shell kubectl get sa waiter-sa 2> /dev/null | tail -n +2 | awk '{if ($$1=="waiter-sa") print "--set=global.waiter.service_account.create=false"}')

# Used in sense
HELM_VALIDATION := $(shell helm version --short | cut -d'+' -f1 | awk -Fv '{if ($$2 > 3.2) print "--disable-openapi-validation"}')

# gets the cluster environment
ENVIRONMENT := $(shell cat $(HOME)/global.yaml | $(YQCMD) -r '.global.environment')

#####  This section is used to ensure that when a `make template x` 
#####  a new file is created instead of ovewritting the same file
BUILD_NUMBER_FILE=build-number.txt
# We need to increment the version even if the build number file exists
.PHONY: $(BUILD_NUMBER_FILE)
# Build number file.  Increment if any object file changes.
$(BUILD_NUMBER_FILE):
	@if ! test -f $(BUILD_NUMBER_FILE); then echo 0 > $(BUILD_NUMBER_FILE); fi
	@echo $$(($$(cat $(BUILD_NUMBER_FILE)) + 1)) > $(BUILD_NUMBER_FILE)
OUTPUT_PATH=./logs
BN=$$(cat $(BUILD_NUMBER_FILE))


cust:
	@echo "Cust: $(CUST)"

home:
	@echo "Home: $(HOME)"

env:
	@echo "Environment: $(ENVIRONMENT)"

verify-identity-exists:
	@kubectl get configmap greymatter-mesh-identity-$(CUST) || (echo -e "\nThe mesh identity [greymatter-mesh-identity-$(CUST)] does not exist.\nRun $$(ccyellow)\"make restore-identity\"$$(ccend) to resore it before uninstalling the mesh.\n" && exit 20)

.PHONY: test
test:
	(echo -e "The mesh identity [greymatter-mesh-identity-$(CUST)] does not exist.\nRun $(ccyellow)\"make restore-identity\"$(ccend) to resore it before uninstalling the mesh." && exit 20)

remove-identity:
	kubectl delete configmap greymatter-mesh-identity-$(CUST)

get-secret-release:
	rm -f temp-secret.yaml
	helm ls -o yaml | $(YQCMD) '.[] | select (.name | test("secret") )' > temp-secret.yaml

restore-identity: get-secret-release
	$(unset SECRET_RELEASE_NAME)
	$(unset SECRET_REVISION)
	$(eval SECRET_RELEASE_NAME=$(shell cat temp-secret.yaml | $(YQCMD) -r .name ))
	$(eval SECRET_REVISION=$(shell cat temp-secret.yaml | $(YQCMD) -r .revision ))
	echo $(SECRET_RELEASE_NAME)
	echo $(SECRET_REVISION)
	helm rollback $(SECRET_RELEASE_NAME) $(SECRET_REVISION)
	$(unset SECRET_RELEASE_NAME)
	$(unset SECRET_REVISION)