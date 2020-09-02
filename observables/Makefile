# oc or kubectl
CLUSTER_CMD=kubectl

NAMESPACE?=observables
LOGSTASH-NAMESPACE?=$(NAMESPACE)

ELASTICSEARCH-NAME?=elasticsearch
KIBANA-NAME?=kibana
LOGSTASH-NAME?=logstash
KAFKA-NAME?=kafka-observables
EKS?=false

# DEBUG=
ifeq ($(TEST),TRUE)
	DRYRUN=--dry-run
endif

CMD=kubectl

pwd_name := $(notdir $(PWD))

.DEFAULT_GOAL := install-observables

install-observables: kafka elasticsearch kibana logstash kibana-proxy

.PHONY: check-namespace
check-namespace:
	$(eval OBS_NS_CHECK=$(shell kubectl get ns | grep $(NAMESPACE) | awk '{if ($$1 == "$(NAMESPACE)") print "present"; else print "not-present"}'))
	if [[ "$(OBS_NS_CHECK)" != "present" ]]; then \
		(make namespace);\
	fi

# make obseravables namespace
namespace:
	kubectl create namespace $(NAMESPACE)

# make observables secrets
copy-credentials:
	@if [ "$(pwd_name)" == "observables" ]; then \
		cp ../credentials.yaml .; \
	else \
		echo "Make sure you are running this from observables makefile"; \
	fi

.PHONY: check-secrets
check-secrets: 
	$(eval SECRET_CHECK=$(shell helm ls -n $(NAMESPACE) | grep secrets | awk '{if ($$1 == "secrets") print "present"; else print "not-present"}'))
	if [[ "$(SECRET_CHECK)" != "present" ]]; then \
		(make secrets);\
	fi

.PHONY: secrets
secrets: copy-credentials
	@if [ "$(pwd_name)" == "observables" ]; then \
		helm install secrets ../secrets -f credentials.yaml -f ../global.yaml -n $(NAMESPACE); \
		kubectl delete secret control-certs -n $(NAMESPACE); \
		kubectl delete secret postgres-credentials -n $(NAMESPACE); \
		kubectl delete secret mongo-certs -n $(NAMESPACE); \
		kubectl delete secret redis-password -n $(NAMESPACE); \
		kubectl delete secret controlapi-certs -n $(NAMESPACE); \
		kubectl delete secret postgres-ssl-certs -n $(NAMESPACE); \
		kubectl delete secret mongo-password -n $(NAMESPACE); \
		kubectl delete secret slo-certs -n $(NAMESPACE); \
		kubectl delete secret jwt-certs -n $(NAMESPACE); \
		kubectl delete secret greymatter-edge-egress -n $(NAMESPACE); \
		kubectl delete secret greymatter-edge-ingress -n $(NAMESPACE); \
		kubectl delete secret dashboard-certs -n $(NAMESPACE); \
		kubectl delete secret data-secrets -n $(NAMESPACE); \
		kubectl delete secret jwt-security -n $(NAMESPACE); \
		rm credentials.yaml; \
	else \
		echo "Make sure you are running this from observables makefile"; \
	fi

# add and update helm repos
helm-dep-up:
	helm repo add elastic https://helm.elastic.co
	helm repo add bitnami https://charts.bitnami.com/bitnami
	helm repo update

# Install stuff
kafka: helm-dep-up
	helm install $(KAFKA-NAME) bitnami/kafka \
		-f custom-values-files/kafka-values.yaml \
		--set zookeeper.volumePermissions.enabled=$(EKS) \
		--namespace $(NAMESPACE) \
		$(DRYRUN) --debug

elasticsearch: helm-dep-up
	if [ "$(EKS)" = "true" ]; then \
		helm install $(ELASTICSEARCH-NAME) elastic/elasticsearch \
			--namespace $(NAMESPACE) \
			-f custom-values-files/elasticsearch-values.yaml \
			--set extraEnvs[0].name=discovery.type,extraEnvs[0].value=single-node \
			--set extraEnvs[1].name=cluster.initial_master_nodes,extraEnvs[1].value= \
			--set sysctlInitContainer.enabled=true \
			--namespace $(NAMESPACE) \
			$(DRYRUN) --debug; \
	else \
		helm install $(ELASTICSEARCH-NAME) elastic/elasticsearch \
			--namespace $(NAMESPACE) \
			-f custom-values-files/elasticsearch-values.yaml \
			--namespace $(NAMESPACE) \
			$(DRYRUN) --debug; \
	fi

kibana: helm-dep-up
	helm install $(KIBANA-NAME) elastic/kibana \
		--namespace $(NAMESPACE) \
		-f custom-values-files/kibana-values.yaml \
		--namespace $(NAMESPACE) \
		$(DRYRUN) --debug

kibana-proxy: helm-dep-up
	helm install $(KIBANA-NAME)-observables-proxy ../proxy \
		--namespace $(NAMESPACE) \
		-f ../global.yaml \
		-f custom-values-files/kibana-proxy-values.yaml \
		--namespace $(NAMESPACE) \
		$(DRYRUN) --debug

logstash: helm-dep-up
	helm fetch elastic/logstash --version 7.5.2
	helm template $(LOGSTASH-NAME) \
		--namespace $(LOGSTASH-NAMESPACE) \
		-f custom-values-files/logstash-values.yaml \
		--set extraEnvs[2].value=$(LOGSTASH-NAMESPACE) \
		logstash-7.5.2.tgz > manifest.yaml
	kubectl apply -f manifest.yaml --namespace $(LOGSTASH-NAMESPACE) --validate=false $(DRYRUN)

# Delete installations
delete-kafka:
	helm del   $(KAFKA-NAME) --namespace $(NAMESPACE)
delete-elasticsearch:
	helm del  $(ELASTICSEARCH-NAME) --namespace $(NAMESPACE)

delete-kibana:
	helm del  $(KIBANA-NAME) --namespace $(NAMESPACE)

delete-kibana-proxy:
	helm del  $(KIBANA-NAME)-observables-proxy --namespace $(NAMESPACE)

delete-logstash:
	kubectl delete statefulset logstash-logstash --namespace $(LOGSTASH-NAMESPACE)
	kubectl delete pdb logstash-logstash-pdb --namespace $(LOGSTASH-NAMESPACE)
	kubectl delete configmap logstash-logstash-config --namespace $(LOGSTASH-NAMESPACE)
	kubectl delete configmap logstash-logstash-pipeline --namespace $(LOGSTASH-NAMESPACE)

destroy-observables: delete-kafka delete-logstash delete-kibana delete-elasticsearch delete-kibana-proxy

