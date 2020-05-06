SHELL := /bin/bash
NAME-SPIRE:=spire
CHART-SPIRE := .

include ../output.mk

wsa-spire:
	$(eval WAITERSACHECK-SPIRE=$(shell kubectl get sa waiter-sa | tail -n +2 | awk '{if ($$1=="waiter-sa") print "--set=global.waiter.service_account.create=false"}'))
	echo $(WAITERSACHECK-SPIRE)

.PHONY: server
server: wsa-spire
	helm install $(NAME-SPIRE)-server server --set=global.environment=kubernetes $(WAITERSACHECK-SPIRE) -f ../global.yaml

.PHONY: agent
agent: wsa-spire
	helm install $(NAME-SPIRE)-agent agent --set=global.environment=kubernetes $(WAITERSACHECK-SPIRE) -f ../global.yaml

clean-spire:
	rm -f ./charts/*

package-spire: clean-spire
	echo "target hit package-spire"
	helm dep up .

template-spire: package-spire $(BUILD_NUMBER_FILE)
	mkdir -p $(OUTPUT_PATH)
	helm template $(NAME-SPIRE) . --set=global.environment=kubernetes $(WAITERSACHECK-SPIRE)  -f ../global.yaml > $(OUTPUT_PATH)/helm-$(NAME-SPIRE)$(BN).yaml

.PHONY: spire
spire: package-spire wsa-spire
	(make server && sleep 20 && make agent)

.PHONY: remove-spire
remove-spire:
	helm uninstall $(shell helm ls | grep agent | awk '{print $$1}')
	helm uninstall $(shell helm ls | grep server | awk '{print $$1}')