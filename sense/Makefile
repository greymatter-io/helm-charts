include ../helpers.mk
NAME-SENSE := sense-$(CUST)-$(RAND)

.PHONY: catalog dashboard slo sense upgrade-sense remove-sense

catalog:
	helm install $(NAME-SENSE) catalog $(WSA_CHECK) -f ../global.yaml

dashboard:
	helm install $(NAME-SENSE) dashboard $(WSA_CHECK) -f ../global.yaml

slo:
	helm install $(NAME-SENSE) slo $(WSA_CHECK) -f ../global.yaml

clean-sense:
	rm -f ./charts/*

package-sense: clean-sense
	helm dep up .

template-sense: package-sense $(BUILD_NUMBER_FILE)
	mkdir -p $(OUTPUT_PATH)
	helm template $(NAME-SENSE) . $(WSA_CHECK)  -f ../global.yaml > $(OUTPUT_PATH)/helm-$(NAME-SENSE)$(BN).yaml

sense: package-sense
	helm install $(NAME-SENSE) . $(WSA_CHECK) -f ../global.yaml --timeout 10m --wait

upgrade-sense: package-sense
	helm upgrade $(NAME-SENSE) . $(WSA_CHECK) -f ../global.yaml --no-hooks --install $(HELM_VALIDATION)

remove-sense:
	helm uninstall $(NAME-SENSE)
