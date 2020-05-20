SHELL := /bin/bash
NAME-DATA:=data
CHART_DATA := .

include ../output.mk

wsa-data:
	$(eval WAITERSACHECK-DATA=$(shell kubectl get sa waiter-sa | tail -n +2 | awk '{if ($$1=="waiter-sa") print "--set=global.waiter.service_account.create=false"}'))
	echo $(WAITERSACHECK-DATA)

.PHONY: gm-data
gm-data: wsa-data
	helm install $(NAME-DATA) gm-data $(WAITERSACHECK-DATA) -f ../global.yaml

clean-data:
	rm -f ./charts/*

package-data: clean-data
	echo "target hit package-data"
	helm dep up .

template-data: package-data $(BUILD_NUMBER_FILE)
	mkdir -p $(OUTPUT_PATH)
	helm template $(NAME-DATA) . $(WAITERSACHECK-DATA)  -f ../global.yaml > $(OUTPUT_PATH)/helm-$(NAME-DATA)$(BN).yaml

.PHONY: data
data: package-data wsa-data
	helm install $(NAME-DATA) . $(WAITERSACHECK-DATA) -f ../global.yaml

.PHONY: remove-data
remove-data:
	helm uninstall $(NAME-DATA)
