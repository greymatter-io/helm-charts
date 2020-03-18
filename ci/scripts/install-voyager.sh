#!/bin/bash
cd $(dirname "${BASH_SOURCE[0]}")
export PROVIDER=minikube
helm repo add appscode https://charts.appscode.com/stable/
helm repo update
helm install voyager-operator appscode/voyager \
  --namespace kube-system \
  --set cloudProvider=$PROVIDER \
  --set enableAnalytics=false \
  --set apiserver.enableAdmissionWebhook=false \
  --version v12.0.0-rc.1
while [[ $(kubectl get pods -n kube-system -l app=voyager -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for pod" && sleep 10; done
