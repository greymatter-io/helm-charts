SHELL := /bin/bash
#  This simple makefile provides an easy shortcut for commonly used helm commands

include secrets/Makefile
# `make credentials` to build out credentials with user input
# `make secrets` deploys the credentials

BUILD_NUMBER_FILE=build-number.txt

# We need to increment the version even if the build number file exists
.PHONY: $(BUILD_NUMBER_FILE)
# Build number file.  Increment if any object file changes.
$(BUILD_NUMBER_FILE):
	@if ! test -f $(BUILD_NUMBER_FILE); then echo 0 > $(BUILD_NUMBER_FILE); fi
	@echo $$(($$(cat $(BUILD_NUMBER_FILE)) + 1)) > $(BUILD_NUMBER_FILE)

.PHONY: minikube
minikube:
	./ci/scripts/minikube.sh

.PHONY: k3d
k3d:
	./ci/scripts/k3d.sh

.IGNORE= destroy
destroy:
	-(make delete)
	-minikube delete
	-k3d delete --name greymatter


# Grey Matter Specific targets
# To target individual sub charts you can go the directory and use the make targets there.

clean: 
	(cd fabric && make clean-fabric)
	(cd data && make clean-data)
	(cd sense && make clean-sense)

dev-dep: clean
	(cd fabric && make package-fabric)
	(cd data && make package-data)
	(cd sense && make package-sense)

check-secrets:
	$(eval SECRET_CHECK=$(shell helm ls | grep secrets | awk '{if ($$1 == "secrets") print "present"; else print "not-present"}'))
	echo $(SECRET_CHECK)
	if [[ "$(SECRET_CHECK)" != "present" ]]; then \
		echo "present" ;\
		(make secrets);\
	fi

install: dev-dep check-secrets
	(cd fabric && make fabric)
	(cd edge && make edge)
	(cd data && make data)
	(cd sense && make sense)


uninstall:
	(cd fabric && make remove-fabric)
	(cd edge && make remove-edge)
	(cd data && make remove-data)
	(cd sense && make remove-sense)

delete: uninstall remove-pvc remove-pods
	@echo "purged greymatter helm release"
	
remove-pvc:
	kubectl delete pvc $$(kubectl get pvc | awk '{print $$1}' | tail -n +2)

remove-pods:
	kubectl delete pods $$(kubectl get pods | awk '{print $$1'} | tail -n +2)


OUTPUT_PATH=./logs

BN=$$(cat $(BUILD_NUMBER_FILE))

template: dev-dep $(BUILD_NUMBER_FILE)
	@echo "Templating the greymatter helm charts"
	mkdir -p $(OUTPUT_PATH)
	helm template greymatter -f ./custom.yaml --name gm-deploy > $(OUTPUT_PATH)/helm-$(BN).yaml