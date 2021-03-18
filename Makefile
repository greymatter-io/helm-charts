include helpers.mk
#  This simple makefile provides an easy shortcut for commonly used helm commands

# `make credentials` to build out credentials with user input
# `make secrets` deploys the credentials

.PHONY: minikube k3d check-secrets install-spire install uninstall secrets remove-secrets credentials observables remove-observables spire-custom-ca lint-subcharts lint-edge-secrets lint-umbrella-charts lint

K3D?=false

minikube:
	./ci/scripts/minikube.sh

k3d:
	./ci/scripts/k3d.sh
  	K3D=true

reveal-endpoint:
	./ci/scripts/show-voyager.sh

.IGNORE=destroy-k3d
destroy-k3d:
	-(make delete)
	-k3d cluster delete greymatter
	-(eval unset KUBECONFIG)

.IGNORE=destroy-minikube
destroy-minikube:
	-(make delete)
	-minikube delete
	-(eval unset KUBECONFIG)

# Grey Matter Specific targets
# To target individual sub charts you can go the directory and use the make targets there.

clean:
	(cd spire && make clean-spire)
	(cd fabric && make clean-fabric)
	(cd sense && make clean-sense)

dev-dep: clean
	(cd spire && make package-spire)
	(cd fabric && make package-fabric)
	(cd sense && make package-sense)

check-secrets:
	@$(eval SECRET_CHECK=$(shell helm ls | grep secrets | awk '{if ($$1 ~ /secrets*/) print "present"; else print "not-present"}'))
	@if [[ "$(SECRET_CHECK)" != "present" ]]; then \
		(make secrets); \
	fi

install-spire:
	$(eval IS=$(shell cat $(HOME)/global.yaml | grep -A3 'spire:'| grep enabled: | awk '{print $$2}'))
	if [ "$(IS)" = "true" ]; then \
		(cd spire && make spire); \
	fi

install: dev-dep check-secrets install-spire
	(cd fabric && make fabric)
	sleep 20
	(cd edge && make edge)
	sleep 20
	if [ "$(K3D)" = "true" ]; then \
		(kubectl patch svc edge -p '{"spec": {"type": "LoadBalancer"}}'); \
	fi
	sleep 20
	(cd sense && make sense)
	(make remove-identity)
	(make reveal-endpoint)


.IGNORE: uninstall
uninstall: verify-identity-exists
	-(cd spire && make remove-spire)
	-(cd fabric && make remove-fabric)
	-(cd edge && make remove-edge)
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
	(cd sense && make template-sense && cp $(OUTPUT_PATH)/* ../$(OUTPUT_PATH)/)	


secrets:
	cd secrets && make secrets

remove-secrets:
	helm uninstall secrets

credentials:
	cd secrets && make credentials

EKS?=false
OBSERVABLES_NAMESPACE?=observables

observables:
	cd observables && \
	make check-namespace NAMESPACE=$(OBSERVABLES_NAMESPACE) && \
	make check-secrets NAMESPACE=$(OBSERVABLES_NAMESPACE) && \
	make install-observables NAMESPACE=$(OBSERVABLES_NAMESPACE) EKS=$(EKS)

remove-observables:
	cd observables && \
	make destroy-observables NAMESPACE=$(OBSERVABLES_NAMESPACE)

spire-custom-ca:
	cd spire && make custom-ca

generate-certs:
    ./certs/gen-certs.sh

lint-subcharts:
	@echo "Lint Fabric, Sense, and Spire subcharts"
	ct lint --config .chart-testing/services.yaml

lint-edge-secrets:
	@echo "Lint Edge and Secrets"
	ct lint --config .chart-testing/edge-secrets.yaml 

lint-umbrella-charts:
	@echo "Lint top level charts"
	ct lint --target-branch release-2.3 --chart-dirs .

lint: lint-subcharts lint-edge-secrets lint-umbrella-charts
