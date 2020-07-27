SHELL := /bin/bash
NAME-SENSE:=sense
CHART-SENSE := .

include ../output.mk

wsa-sense:
	$(eval WAITERSACHECK-SENSE=$(shell kubectl get sa waiter-sa | tail -n +2 | awk '{if ($$1=="waiter-sa") print "--set=global.waiter.service_account.create=false"}'))
	@echo $(WAITERSACHECK-SENSE)

helm-validator:
	$(eval HELM_VALIDATION=$(shell helm version --short | cut -d'+' -f1 | awk -Fv '{if ($$2 > 3.2) print "--disable-openapi-validation"}'))
	@echo $(HELM_VALIDATION)

.PHONY: catalog
catalog: wsa-sense
	helm install $(NAME-SENSE) catalog $(WAITERSACHECK-SENSE) -f ../global.yaml

.PHONY: dashboard
dashboard: wsa-sense
	helm install $(NAME-SENSE) dashboard $(WAITERSACHECK-SENSE) -f ../global.yaml

.PHONY: slo
slo: wsa-sense
	helm install $(NAME-SENSE) slo $(WAITERSACHECK-SENSE) -f ../global.yaml

clean-sense:
	rm -f ./charts/*

package-sense: clean-sense
	echo "target hit package-sense"
	helm dep up .

template-sense: package-sense $(BUILD_NUMBER_FILE)
	mkdir -p $(OUTPUT_PATH)
	helm template $(NAME-SENSE) . $(WAITERSACHECK-SENSE)  -f ../global.yaml > $(OUTPUT_PATH)/helm-$(NAME-SENSE)$(BN).yaml

.PHONY: sense
sense: package-sense wsa-sense
	helm install $(NAME-SENSE) . $(WAITERSACHECK-SENSE) -f ../global.yaml --timeout 10m --wait

.PHONY: upgrade-sense
upgrade-sense: wsa-sense helm-validator
	helm upgrade $(NAME-SENSE) . $(WAITERSACHECK-SENSE) -f ../global.yaml --no-hooks --install $(HELM_VALIDATION)

.PHONY: remove-sense
remove-sense:
	helm uninstall $(NAME-SENSE)
