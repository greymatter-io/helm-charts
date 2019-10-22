#!/bin/bash
export PROVIDER=minikube
helm repo add appscode https://charts.appscode.com/stable/
helm repo update
helm install appscode/voyager --name voyager-operator --version 10.0.0 \
  --namespace kube-system \
  --set cloudProvider=$PROVIDER \
  --set enableAnalytics=false \
  --set apiserver.enableAdmissionWebhook=false
while [[ $(kubectl get pods -n kube-system -l app=voyager -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for pod" && sleep 10; done
