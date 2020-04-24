SHELL := /bin/bash
NAME-FABRIC:=fabric
CHART-FABRIC := .

include ../output.mk

wsa-fabric:
	$(eval WAITERSACHECK-FABRIC=$(shell kubectl get sa waiter-sa | tail -n +2 | awk '{if ($$1=="waiter-sa") print "--set=global.waiter.service_account.create=false"}'))

.PHONY: control
control: wsa-fabric
	helm install $(NAME-FABRIC) control --set=global.environment=kubernetes $(WAITERSACHECK-FABRIC)

.PHONY: control-api
control-api: wsa-fabric
	helm install control-api-$(NAME-FABRIC) control-api  --set=global.environment=kubernetes $(WAITERSACHECK-FABRIC)

.PHONY: jwt
jwt: wsa-data
	helm install jwt-$(NAME-FABRIC) jwt --set=global.environment=kubernetes $(WAITERSACHECK-FABRIC) -f ../global.yaml

.PHONY: jwt-gov
jwt-gov: wsa-data
	helm install $(NAME-FABRIC) jwt-gov --set=global.environment=kubernetes $(WAITERSACHECK-FABRIC) -f ../global.yaml

clean-fabric:
	rm -f ./charts/*

package-fabric: clean-fabric
	echo "target hit package-fabric"
	helm dep up .

template-fabric: package-fabric $(BUILD_NUMBER_FILE)
	mkdir -p $(OUTPUT_PATH)
	helm template $(NAME-FABRIC) . --set=global.environment=kubernetes $(WAITERSACHECK-FABRIC) > $(OUTPUT_PATH)/helm-$(NAME-FABRIC)$(BN).yaml

.PHONY: fabric
fabric: package-fabric wsa-fabric
	helm install $(NAME-FABRIC) . --set=global.environment=kubernetes $(WAITERSACHECK-FABRIC)

.PHONY: remove-fabric
remove-fabric:
	helm uninstall $(NAME-FABRIC)
