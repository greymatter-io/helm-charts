SHELL := /bin/bash
#  This simple makefile provides an easy shortcut for commonly used helm commands

include output.mk
include secrets/Makefile
# `make credentials` to build out credentials with user input
# `make secrets` deploys the credentials

.PHONY: minikube
minikube:
	./ci/scripts/minikube.sh

.PHONY: k3d
k3d:
	./ci/scripts/k3d.sh
	@echo -e "\nSet KUBECONFIG in your shell by running:"
	@echo -e "export KUBECONFIG=$$(k3d get-kubeconfig --name='greymatter')"

reveal-endpoint:
	./ci/scripts/show-voyager.sh

.IGNORE= destroy
destroy:
	-(make delete)
	-minikube delete
	-k3d delete --name greymatter
	-(eval unset KUBECONFIG)


# Grey Matter Specific targets
# To target individual sub charts you can go the directory and use the make targets there.

clean:
	(cd spire && make clean-spire)
	(cd fabric && make clean-fabric)
	(cd data && make clean-data)
	(cd sense && make clean-sense)

dev-dep: clean
	(cd spire && make package-spire)
	(cd fabric && make package-fabric)
	(cd data && make package-data)
	(cd sense && make package-sense)

.PHONY: check-secrets
check-secrets:
	$(eval SECRET_CHECK=$(shell helm ls | grep secrets | awk '{if ($$1 == "secrets") print "present"; else print "not-present"}'))
	if [[ "$(SECRET_CHECK)" != "present" ]]; then \
		(make secrets);\
	fi

.PHONY: install-spire
install-spire:
	$(eval IS=$(shell cat global.yaml | grep -A3 'spire:'| grep enabled: | awk '{print $$2}'))
	if [ "$(IS)" = "true" ]; then \
		(cd spire && make spire); \
	fi

.PHONY: install
install: dev-dep check-secrets install-spire
	(cd fabric && make fabric)
	sleep 20
	(cd edge && make edge)
	sleep 20
	(cd data && make data)
	sleep 20
	(cd sense && make sense)
	(make reveal-endpoint)

.IGNORE: uninstall
.PHONY: uninstall
uninstall:
	-(cd spire && make remove-spire)
	-(cd fabric && make remove-fabric)
	-(cd edge && make remove-edge)
	-(cd data && make remove-data)
	-(cd sense && make remove-sense)

delete: uninstall remove-pvc remove-pods
	@echo "purged greymatter helm release"
	
remove-pvc:
	kubectl delete pvc $$(kubectl get pvc | awk '{print $$1}' | tail -n +2)

remove-pods:
	kubectl delete pods $$(kubectl get pods | awk '{print $$1'} | tail -n +2)


OUTPUT_PATH=./logs

template: dev-dep $(BUILD_NUMBER_FILE)
	@echo "Templating the greymatter helm charts"
	mkdir -p $(OUTPUT_PATH)
	(cd spire && make template-spire && cp $(OUTPUT_PATH)/* ../$(OUTPUT_PATH)/)
	(cd fabric && make template-fabric && cp $(OUTPUT_PATH)/* ../$(OUTPUT_PATH)/)
	(cd edge && make template-edge && cp $(OUTPUT_PATH)/* ../$(OUTPUT_PATH)/)
	(cd data && make template-data && cp $(OUTPUT_PATH)/* ../$(OUTPUT_PATH)/)
	(cd sense && make template-sense && cp $(OUTPUT_PATH)/* ../$(OUTPUT_PATH)/)	