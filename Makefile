#  This simple makefile provides an easy shortcut for commonly used helm commands

include ./voyager/Makefile

BUILD_NUMBER_FILE=build-number.txt

# We need to increment the version even if the build number file exists
.PHONY: $(BUILD_NUMBER_FILE)
# Build number file.  Increment if any object file changes.
$(BUILD_NUMBER_FILE):
	@if ! test -f $(BUILD_NUMBER_FILE); then echo 0 > $(BUILD_NUMBER_FILE); fi
	@echo $$(($$(cat $(BUILD_NUMBER_FILE)) + 1)) > $(BUILD_NUMBER_FILE)

credentials:
	./ci/scripts/build-credentials.sh

fresh: credentials
	./ci/scripts/minikube.sh

.PHONY: minikube
minikube:
	./ci/scripts/minikube.sh
	
# For reference equivalent to ./ci/scripts/minikube.sh but without extra aws handling
#   minikube start --memory 6144 --cpus 6		
#   helm init --wait	
#   ./ci/scripts/install-voyager.sh	
#   helm dep up greymatter
#   helm install greymatter -f greymatter.yaml -f greymatter-secrets.yaml -f credentials.yaml --set global.environment=kubernetes -n gm-deploy	
#   ./ci/scripts/show-voyager.sh

clean:
	rm -rf fabric/charts
	rm -rf edge/charts
	rm -rf data/charts
	rm -rf sense/charts

dev-dep: clean
	helm dep up fabric/ --skip-refresh
	helm dep up edge/ --skip-refresh
	helm dep up data/ --skip-refresh
	helm dep up sense/ --skip-refresh

# dep: clean
# 	helm dep up greymatter/

install: dev-dep
	@echo "installing greymatter helm charts"
	helm install greymatter -f ./custom.yaml --name gm-deploy

destroy:
	minikube delete

OUTPUT_PATH=./logs

BN=$$(cat $(BUILD_NUMBER_FILE))

template: dev-dep $(BUILD_NUMBER_FILE)
	@echo "templating the greymatter helm charts"
	mkdir -p $(OUTPUT_PATH)
	helm template greymatter -f ./custom.yaml --name gm-deploy > $(OUTPUT_PATH)/helm-$(BN).yaml

delete:
	@echo "purging greymatter helm release"
	helm del --purge gm-deploy
