SHELL := /bin/bash
NAME-FABRIC:=fabric
CHART-FABRIC := .

wsa-fabric:
	$(eval WAITERSACHECK-FABRIC=$(shell kubectl get sa waiter-sa | tail -n +2 | awk '{if ($$1=="waiter-sa") print "--set=global.waiter.service_account.create=false"}'))

.PHONY: control
control: wsa-fabric
	helm install $(NAME-FABRIC) control --set=global.environment=kubernetes $(WAITERSACHECK-FABRIC)

.PHONY: control-api
control-api: wsa-fabric
	helm install control-api-$(NAME-FABRIC) control-api  --set=global.environment=kubernetes $(WAITERSACHECK-FABRIC)

clean-fabric:
	rm -f ./charts/*

package-fabric: clean-fabric
	echo "target hit package-fabric"
	helm dep up .

.PHONY: fabric
fabric: package-fabric wsa-fabric
	helm install $(NAME-FABRIC) . --set=global.environment=kubernetes $(WAITERSACHECK-FABRIC)

.PHONY: remove-fabric
remove-fabric:
	helm uninstall $(NAME-FABRIC)
