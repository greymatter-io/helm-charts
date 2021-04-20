include ../helpers.mk

NAME-EDGE := edge-$(CUST)

.PHONY: edge upgrade-edge clean-edge remove-edge

edge:
	helm install $(NAME-EDGE) . -f ../global.yaml; \

upgrade-edge: package-edge
	helm upgrade $(NAME-EDGE) . -f ../global.yaml

clean-edge:
	rm -f ./charts/*

remove-edge:
	helm uninstall $(NAME-EDGE)
	
template-edge: $(BUILD_NUMBER_FILE)
	mkdir -p $(OUTPUT_PATH)
	helm template edge . --set=global.environment=kubernetes  -f ../global.yaml > $(OUTPUT_PATH)/helm-edge$(BN).yaml
