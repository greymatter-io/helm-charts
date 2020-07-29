SHELL := /bin/bash

include ../output.mk

mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
current_dir := $(notdir $(patsubst %/,%,$(dir $(mkfile_path))))
pwd_name := $(notdir $(PWD))

.PHONY: credentials
credentials:
	./../ci/scripts/build-credentials.sh

copy-credentials:
	cp ../credentials.yaml .

template-secrets: $(BUILD_NUMBER_FILE)
	mkdir -p $(OUTPUT_PATH)
	helm template secrets . --set=global.environment=kubernetes   -f ../credentials.yaml -f ../global.yaml > $(OUTPUT_PATH)/helm-secrets$(BN).yaml

.PHONY: secrets
secrets: copy-credentials values-validation
	helm install secrets . -f credentials.yaml -f ../global.yaml
	rm credentials.yaml

.PHONY: upgrade-secrets
upgrade-secrets: copy-credentials values-validation
	helm upgrade secrets . -f credentials.yaml -f ../global.yaml --install 
	rm credentials.yaml

.PHONY: remove-secrets
remove-secrets:
	helm uninstall secrets


values-validation:
	# Ensure that the rds.enabled is true in secrets and in fabric values files
	@if [ "$(shell cat values.yaml | grep -A1 rds | grep enabled: | awk '{print $$2}')" == "$(shell cat ../sense/values.yaml | grep -A1 rds | grep enabled: | awk '{print $$2}')" ]; then \
		echo "rds.enabled in secrets/values.yaml and sense/values.yaml match"; \
	else \
		echo "rds.enabled in secrets/values.yaml and sense/values.yaml DO NOT MATCH.  Secrets will not be created"; \
		exit 2;\
	fi
