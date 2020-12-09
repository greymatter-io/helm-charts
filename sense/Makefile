SHELL := /bin/bash
NAME-SENSE:=sense
CHART-SENSE := .

include ../output.mk

wsa-sense:
	$(eval WAITERSACHECK-SENSE=$(shell kubectl get sa waiter-sa 2> /dev/null | tail -n +2 | awk '{if ($$1=="waiter-sa") print "--set=global.waiter.service_account.create=false"}'))

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
	helm dep up .

template-sense: package-sense $(BUILD_NUMBER_FILE)
	mkdir -p $(OUTPUT_PATH)
	helm template $(NAME-SENSE) . $(WAITERSACHECK-SENSE)  -f ../global.yaml > $(OUTPUT_PATH)/helm-$(NAME-SENSE)$(BN).yaml

.PHONY: sense
sense: package-sense wsa-sense
	helm install $(NAME-SENSE) . $(WAITERSACHECK-SENSE) -f ../global.yaml --timeout 10m --wait

	
check-prom-rb:
	$(eval CURRENT_KIND=$(shell kubectl get RoleBinding prometheus-sa-rolebinding -o json | jq -r '.roleRef.kind'))
	$(eval DESIRED_KIND=$(shell cat dashboard/values.yaml | yq -r '.prometheus.service_account.kind'))
	if [ -z "$(CURRENT_KIND)" ] || [ "$(DESIRED_KIND)" == "$(CURRENT_KIND)" ]; then \
		echo "They Match or current kind does not exist"; \
	else \
		# echo "The current prometheus rolebinding does not match the kind that you are trying to upgrade too.  "; \
		# echo "This requires manually deleting the role and rolebinding with: "; \
		# echo "kubectl delete RoleBinding prometheus-sa-rolebinding"; \
		# exit 3; \
		kubectl delete RoleBinding prometheus-sa-rolebinding; \
	fi

.PHONY: upgrade-sense
upgrade-sense: wsa-sense package-sense helm-validator check-prom-rb
	helm upgrade $(NAME-SENSE) . $(WAITERSACHECK-SENSE) -f ../global.yaml --no-hooks --install $(HELM_VALIDATION)

.PHONY: remove-sense
remove-sense:
	helm uninstall $(NAME-SENSE)
