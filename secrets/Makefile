SHELL := /bin/bash

mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
current_dir := $(notdir $(patsubst %/,%,$(dir $(mkfile_path))))
pwd_name := $(notdir $(PWD))

.PHONY: credentials
credentials:
	@if [ "$(pwd_name)" == "helm-charts" ]; then \
		./ci/scripts/build-credentials.sh; \
	elif [ "$(pwd_name)" == "secrets" ]; then \
		./../ci/scripts/build-credentials.sh; \
	else \
		echo "Make sure you are running this from helm-charts or secrets makefile"; \
	fi

copy-credentials:
	@if [ "$(pwd_name)" == "helm-charts" ]; then \
		cp ./credentials.yaml ./secrets/credentials.yaml; \
	elif [ "$(pwd_name)" == "secrets" ]; then \
		cp ../credentials.yaml .; \
	else \
		echo "Make sure you are running this from helm-charts or secrets makefile"; \
	fi

.PHONY: secrets
secrets: copy-credentials
	@if [ "$(pwd_name)" == "helm-charts" ]; then \
		helm install secrets secrets -f credentials.yaml -f global.yaml; \
		rm secrets/credentials.yaml; \
	elif [ "$(pwd_name)" == "secrets" ]; then \
		helm install secrets . -f credentials.yaml -f ../global.yaml; \
		rm credentials.yaml; \
	else \
		echo "Make sure you are running this from helm-charts or secrets makefile"; \
	fi

.PHONY: remove-secrets
remove-secrets:
	helm uninstall secrets
