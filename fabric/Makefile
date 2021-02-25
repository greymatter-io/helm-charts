include ../helpers.mk

NAME-FABRIC := fabric-$(CUST)-$(RAND)


.PHONY: control control-api jwt jwt-gov fabric upgrade-fabric remove-fabric

control:
	helm install $(NAME-FABRIC) control $(WSA_CHECK) -f $(HOME)/global.yaml

control-api:
	helm install control-api-$(NAME-FABRIC) control-api $(WSA_CHECK) -f $(HOME)/global.yaml

jwt: wsa-data
	helm install jwt-$(NAME-FABRIC) jwt $(WSA_CHECK) -f $(HOME)/global.yaml

jwt-gov: wsa-data
	helm install $(NAME-FABRIC) jwt-gov $(WSA_CHECK) -f $(HOME)/global.yaml

clean-fabric:
	rm -f ./charts/*

package-fabric: clean-fabric
	echo "target hit package-fabric"
	helm dep up .

template-fabric: package-fabric $(BUILD_NUMBER_FILE)
	mkdir -p $(OUTPUT_PATH)
	helm template $(NAME-FABRIC) . $(WSA_CHECK)  -f $(HOME)/global.yaml > $(OUTPUT_PATH)/helm-$(NAME-FABRIC)$(BN).yaml

fabric: package-fabric
	helm install $(NAME-FABRIC) . $(WSA_CHECK) -f $(HOME)/global.yaml

upgrade-fabric: package-fabric
	helm upgrade $(NAME-FABRIC) . $(WSA_CHECK) -f $(HOME)/global.yaml --no-hooks


remove-fabric:
	helm uninstall $(NAME-FABRIC)
