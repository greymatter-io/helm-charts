SHELL := /bin/bash
mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
current_dir := $(notdir $(patsubst %/,%,$(dir $(mkfile_path))))
CUST := development
# CUST := $(shell kubectl get configmap greymatter-mesh-identity-$(CUST) -o jsonpath='{.data.customer}')
RAND := $(shell kubectl get configmap greymatter-mesh-identity-$(CUST) -o jsonpath='{.data.rand_identifier}')
NAME-EDGE := edge-$(CUST)-$(RAND)

pwd_name := $(notdir $(PWD))

include ../output.mk

.PHONY: edge
edge:
	if [ "$(pwd_name)" == "edge" ]; then \
		echo "run in makefile directory"; \
		helm install $(NAME-EDGE) . -f ../global.yaml; \
	else \
		echo "run in helm-charts top directory"; \
		helm install $(NAME-EDGE) edge -f ../global.yaml; \
	fi

.PHONY: upgrade-edge
upgrade-edge: package-edge
	helm upgrade $(NAME-EDGE) . -f ../global.yaml

.PHONY: clean-edge
clean-edge:
	rm -f ./charts/*

.PHONY: remove-edge
remove-edge:
	helm uninstall $(NAME-EDGE)
	
template-edge: $(BUILD_NUMBER_FILE)
	mkdir -p $(OUTPUT_PATH)
	helm template edge . --set=global.environment=kubernetes  -f ../global.yaml > $(OUTPUT_PATH)/helm-edge$(BN).yaml

print:
	echo $(RAND)