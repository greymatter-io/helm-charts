include ../helpers.mk

NAME-SPIRE-AGENT := spire-agent-$(CUST)-$(RAND)
NAME-SPIRE-SERVER := spire-server-$(CUST)-$(RAND)

.PHONY: server agent spire remove-spire custom-ca


server: 
	helm install $(NAME-SPIRE-SERVER) server $(WSA_CHECK) -f $(HOME)/global.yaml

agent:
	@if [ "$(ENVIRONMENT)" == "openshift" ]; then \
		helm install $(NAME-SPIRE-AGENT) agent $(WSA_CHECK) -f $(HOME)/global.yaml; \
        oc adm policy add-scc-to-user hostaccess system:serviceaccount:spire:agent;\
		oc adm policy add-scc-to-user privileged system:serviceaccount:spire:agent;\
	else \
		helm install $(NAME-SPIRE-AGENT) agent $(WSA_CHECK) -f $(HOME)/global.yaml; \
    fi

clean-spire:
	rm -f ./charts/*

package-spire: clean-spire
	echo "target hit package-spire"
	helm dep up .

template-spire: package-spire $(BUILD_NUMBER_FILE)
	mkdir -p $(OUTPUT_PATH)
	helm template $(NAME-SPIRE-AGENT) agent $(WSA_CHECK)  -f $(HOME)/global.yaml > $(OUTPUT_PATH)/helm-$(NAME-SPIRE-AGENT)$(BN).yaml
	helm template $(NAME-SPIRE-SERVER) agent $(WSA_CHECK)  -f $(HOME)/global.yaml > $(OUTPUT_PATH)/helm-$(NAME-SPIRE-SERVER)$(BN).yaml

spire: package-spire 
	(make server && sleep 20 && make agent)

remove-spire:
	helm uninstall $(NAME-SPIRE-AGENT)
	helm uninstall $(NAME-SPIRE-SERVER)

custom-ca:
	./../ci/scripts/spire-ca.sh

env:
	echo $(ENVIRONMENT)