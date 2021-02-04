SHELL := /bin/bash
CUST := development
RAND := $(shell kubectl get configmap greymatter-mesh-identity-$(CUST) -o jsonpath='{.data.rand_identifier}')
NAME-SPIRE := spire-$(CUST)-$(RAND)
CHART-SPIRE := .

include ../output.mk

wsa-spire:
	$(eval WAITERSACHECK-SPIRE=$(shell kubectl get sa waiter-sa 2> /dev/null | tail -n +2 | awk '{if ($$1=="waiter-sa") print "--set=global.waiter.service_account.create=false"}'))

envirionemt-check:
	$(eval ENVIRONMENT=$(shell grep -hri "environment:"  ../global.yaml  | cut -d ':' -f 2 | xargs))

.PHONY: server
server: wsa-spire
	helm install $(NAME-SPIRE)-server server $(WAITERSACHECK-SPIRE) -f ../global.yaml

.PHONY: agent
agent: wsa-spire envirionemt-check
	@if [ "$(ENVIRONMENT)" == "openshift" ]; then \
		helm install $(NAME-SPIRE)-agent agent $(WAITERSACHECK-SPIRE) -f ../global.yaml; \
        oc adm policy add-scc-to-user hostaccess system:serviceaccount:spire:agent;\
		oc adm policy add-scc-to-user privileged system:serviceaccount:spire:agent;\
	else \
		helm install $(NAME-SPIRE)-agent agent $(WAITERSACHECK-SPIRE) -f ../global.yaml; \
    fi

clean-spire:
	rm -f ./charts/*

package-spire: clean-spire
	echo "target hit package-spire"
	helm dep up .

template-spire: package-spire $(BUILD_NUMBER_FILE)
	mkdir -p $(OUTPUT_PATH)
	helm template $(NAME-SPIRE) . $(WAITERSACHECK-SPIRE)  -f ../global.yaml > $(OUTPUT_PATH)/helm-$(NAME-SPIRE)$(BN).yaml

.PHONY: spire
spire: package-spire wsa-spire
	(make server && sleep 20 && make agent)

.PHONY: remove-spire
remove-spire:
	helm uninstall $(shell helm ls | grep agent | awk '{print $$1}')
	helm uninstall $(shell helm ls | grep server | awk '{print $$1}')

.PHONY: custom-ca
custom-ca:
	./../ci/scripts/spire-ca.sh
	