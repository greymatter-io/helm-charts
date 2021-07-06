include ../helpers.mk

NAME-DATA := data-$(CUST)-$(RAND)

.PHONY: gm-data clean-data package-data template-data data upgrade-data remove-data

gm-data:
	helm install $(NAME-DATA) gm-data $(WSA_CHECK) -f ../global.yaml

clean-data:
	rm -f ./charts/*

package-data: clean-data
	helm dep up .

template-data: package-data $(BUILD_NUMBER_FILE)
	mkdir -p $(OUTPUT_PATH)
	helm template $(NAME-DATA) . $(WSA_CHECK)  -f ../global.yaml > $(OUTPUT_PATH)/helm-$(NAME-DATA)$(BN).yaml

.PHONY: data
data: package-data
	helm install $(NAME-DATA) . $(WSA_CHECK) -f ../global.yaml

.PHONY: upgrade-data
upgrade-data: package-data
	helm upgrade $(NAME-DATA) . $(WSA_CHECK) -f ../global.yaml

.PHONY: remove-data
remove-data:
	helm uninstall $(NAME-DATA)
