BUILD_NUMBER_FILE=build-number.txt

# We need to increment the version even if the build number file exists
.PHONY: $(BUILD_NUMBER_FILE)
# Build number file.  Increment if any object file changes.
$(BUILD_NUMBER_FILE):
	@if ! test -f $(BUILD_NUMBER_FILE); then echo 0 > $(BUILD_NUMBER_FILE); fi
	@echo $$(($$(cat $(BUILD_NUMBER_FILE)) + 1)) > $(BUILD_NUMBER_FILE)
OUTPUT_PATH=./logs

BN=$$(cat $(BUILD_NUMBER_FILE))

SHELL := /bin/bash

# These are used for the helm release name
YQCMD := docker run -i docker.greymatter.io/internal/yq:2.4.1
CUST := $(shell cat ../global.yaml | $(YQCMD) -r '.global.release.customer' )
RAND := $(shell kubectl get configmap greymatter-mesh-identity-$(CUST) -o jsonpath='{.data.rand_identifier}')

