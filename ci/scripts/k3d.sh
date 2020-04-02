#!/bin/bash

# install k3d 1.6.0
curl -s https://raw.githubusercontent.com/rancher/k3d/master/install.sh | TAG=v1.6.0 bash

k3d create --workers 4 --name greymatter --publish 30000:10808
while [[ $(k3d get-kubeconfig --name='greymatter') != *kubeconfig.yaml ]]; do echo "echo waiting for k3d cluster to start up" && sleep 10; done
export KUBECONFIG="$(k3d get-kubeconfig --name='greymatter')"
echo "Cluster is connected"