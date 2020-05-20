# oc or kubectl
CLUSTER_CMD=kubectl

NAMESPACE?=observables
LOGSTASH-NAMESPACE?=$(NAMESPACE)

ELASTICSEARCH-NAME?=elasticsearch
KIBANA-NAME?=kibana
LOGSTASH-NAME?=logstash
KAFKA-NAME?=kafka-observables


# DEBUG=
ifeq ($(TEST),TRUE)
	DRYRUN=--dry-run
endif

CMD=kubectl



.DEFAULT_GOAL := install-observables

install-observables: kafka elasticsearch kibana logstash kibana-proxy

# make obseravables namespace
namespace:
	kubectl create namespace $(NAMESPACE)

# add and update helm repos
helm-dep-up:
	helm repo add elastic https://helm.elastic.co
	helm repo add bitnami https://charts.bitnami.com/bitnami
	helm repo update

# Install stuff
kafka: helm-dep-up
	helm install $(KAFKA-NAME) bitnami/kafka \
		-f custom-values-files/kafka-values.yaml \
		--namespace $(NAMESPACE) \
		$(DRYRUN) --debug

elasticsearch: helm-dep-up
	helm install $(ELASTICSEARCH-NAME) elastic/elasticsearch \
		--namespace $(NAMESPACE) \
		-f custom-values-files/elasticsearch-values.yaml \
		--namespace $(NAMESPACE) \
		$(DRYRUN) --debug

kibana: helm-dep-up
	helm install $(KIBANA-NAME) elastic/kibana \
		--namespace $(NAMESPACE) \
		-f custom-values-files/kibana-values.yaml \
		--namespace $(NAMESPACE) \
		$(DRYRUN) --debug

kibana-proxy: helm-dep-up
	helm install $(KIBANA-NAME)-observables-proxy ../proxy \
		--namespace $(NAMESPACE) \
		-f custom-values-files/kibana-proxy-values.yaml \
		--namespace $(NAMESPACE) \
		--set=global.spire.enabled=true \
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

