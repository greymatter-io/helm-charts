SHELL := /bin/bash
NAME-FABRIC:=fabric
CHART-FABRIC := .

include ../output.mk

wsa-fabric:
	$(eval WAITERSACHECK-FABRIC=$(shell kubectl get sa waiter-sa | tail -n +2 | awk '{if ($$1=="waiter-sa") print "--set=global.waiter.service_account.create=false"}'))

.PHONY: control
control: wsa-fabric
	helm install $(NAME-FABRIC) control $(WAITERSACHECK-FABRIC) -f ../global.yaml

.PHONY: control-api
control-api: wsa-fabric
	helm install control-api-$(NAME-FABRIC) control-api $(WAITERSACHECK-FABRIC) -f ../global.yaml

.PHONY: jwt
jwt: wsa-data
	helm install jwt-$(NAME-FABRIC) jwt $(WAITERSACHECK-FABRIC) -f ../global.yaml

.PHONY: jwt-gov
jwt-gov: wsa-data
	helm install $(NAME-FABRIC) jwt-gov $(WAITERSACHECK-FABRIC) -f ../global.yaml

clean-fabric:
	rm -f ./charts/*

package-fabric: clean-fabric
	echo "target hit package-fabric"
	helm dep up .

template-fabric: package-fabric $(BUILD_NUMBER_FILE)
	mkdir -p $(OUTPUT_PATH)
	helm template $(NAME-FABRIC) . $(WAITERSACHECK-FABRIC)  -f ../global.yaml > $(OUTPUT_PATH)/helm-$(NAME-FABRIC)$(BN).yaml

.PHONY: fabric
fabric: package-fabric wsa-fabric
	helm install $(NAME-FABRIC) . $(WAITERSACHECK-FABRIC) -f ../global.yaml

.PHONY: upgrade-fabric
upgrade-fabric: wsa-fabric
	helm upgrade $(NAME-FABRIC) . $(WAITERSACHECK-FABRIC) -f ../global.yaml --no-hooks


.PHONY: remove-fabric
remove-fabric:
	helm uninstall $(NAME-FABRIC)
