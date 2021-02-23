include ../helpers.mk

NAME-SPIRE-AGENT := spire-agent-$(CUST)-$(RAND)
NAME-SPIRE-SERVER := spire-server-$(CUST)-$(RAND)


wsa-spire:
	$(eval WAITERSACHECK-SPIRE=$(shell kubectl get sa waiter-sa 2> /dev/null | tail -n +2 | awk '{if ($$1=="waiter-sa") print "--set=global.waiter.service_account.create=false"}'))

envirionemt-check:
	$(eval ENVIRONMENT=$(shell grep -hri "environment:"  ../global.yaml  | cut -d ':' -f 2 | xargs))

.PHONY: server
server: wsa-spire
	helm install $(NAME-SPIRE-SERVER) server $(WAITERSACHECK-SPIRE) -f ../global.yaml

.PHONY: agent
agent: wsa-spire envirionemt-check
	@if [ "$(ENVIRONMENT)" == "openshift" ]; then \
		helm install $(NAME-SPIRE-AGENT) agent $(WAITERSACHECK-SPIRE) -f ../global.yaml; \
        oc adm policy add-scc-to-user hostaccess system:serviceaccount:spire:agent;\
		oc adm policy add-scc-to-user privileged system:serviceaccount:spire:agent;\
	else \
		helm install $(NAME-SPIRE-AGENT) agent $(WAITERSACHECK-SPIRE) -f ../global.yaml; \
    fi

clean-spire:
	rm -f ./charts/*

package-spire: clean-spire
	echo "target hit package-spire"
	helm dep up .

template-spire: package-spire $(BUILD_NUMBER_FILE)
	mkdir -p $(OUTPUT_PATH)
	helm template $(NAME-SPIRE-AGENT) agent $(WAITERSACHECK-SPIRE)  -f ../global.yaml > $(OUTPUT_PATH)/helm-$(NAME-SPIRE-AGENT)$(BN).yaml
	helm template $(NAME-SPIRE-SERVER) agent $(WAITERSACHECK-SPIRE)  -f ../global.yaml > $(OUTPUT_PATH)/helm-$(NAME-SPIRE-SERVER)$(BN).yaml

.PHONY: spire
spire: package-spire wsa-spire
	(make server && sleep 20 && make agent)

.PHONY: remove-spire
remove-spire:
	helm uninstall $(NAME-SPIRE-AGENT)
	helm uninstall $(NAME-SPIRE-SERVER)

.PHONY: custom-ca
custom-ca:
	./../ci/scripts/spire-ca.sh
	