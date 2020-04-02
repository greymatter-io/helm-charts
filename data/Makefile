SHELL := /bin/bash
NAME-DATA:=data
CHART_DATA := .

include ../output.mk

wsa-data:
	$(eval WAITERSACHECK-DATA=$(shell kubectl get sa waiter-sa | tail -n +2 | awk '{if ($$1=="waiter-sa") print "--set=global.waiter.service_account.create=false"}'))
	echo $(WAITERSACHECK-DATA)

.PHONY: gm-data
gm-data: wsa-data
	helm install $(NAME-DATA) gm-data --set=global.environment=kubernetes $(WAITERSACHECK-DATA)

.PHONY: jwt
jwt: wsa-data
	helm install jwt-$(NAME-DATA) jwt --set=global.environment=kubernetes $(WAITERSACHECK-DATA)

.PHONY: jwt-gov
jwt-gov: wsa-data
	helm install $(NAME-DATA) jwt-gov --set=global.environment=kubernetes $(WAITERSACHECK-DATA)

clean-data:
	rm -f ./charts/*

package-data: clean-data
	echo "target hit package-data"
	helm dep up .

template-data: package-data $(BUILD_NUMBER_FILE)
	mkdir -p $(OUTPUT_PATH)
	helm template $(NAME-DATA) . --set=global.environment=kubernetes $(WAITERSACHECK-DATA) > $(OUTPUT_PATH)/helm-$(NAME-DATA)$(BN).yaml

.PHONY: data
data: package-data wsa-data
	helm install $(NAME-DATA) . --set=global.environment=kubernetes $(WAITERSACHECK-DATA)

.PHONY: remove-data
remove-data:
	helm uninstall $(NAME-DATA)