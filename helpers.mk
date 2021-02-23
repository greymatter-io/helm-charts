# Shell sets the default behaviour for all shell functions running in the makefiles
SHELL := /bin/bash

# These are used for the helm release name (to uninstall and install and put inplace the mesh identity configmap)
YQCMD := docker run -i docker.greymatter.io/internal/yq:2.4.1
CUST := $(shell cat ../global.yaml | $(YQCMD) -r '.global.release.customer' )
RAND := $(shell kubectl get configmap greymatter-mesh-identity-$(CUST) -o jsonpath='{.data.rand_identifier}')

# Service account creation is set to true by default and this automates the disableing of these in makefiles
WSA_CHECK := $(shell kubectl get sa waiter-sa 2> /dev/null | tail -n +2 | awk '{if ($$1=="waiter-sa") print "--set=global.waiter.service_account.create=false"}')

# Used in sense
HELM_VALIDATION := $(shell helm version --short | cut -d'+' -f1 | awk -Fv '{if ($$2 > 3.2) print "--disable-openapi-validation"}')

# gets the cluster environment
ENVIRONMENT := $(shell cat ../global.yaml | $(YQCMD) -r '.global.environment')

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
