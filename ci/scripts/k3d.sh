#!/bin/bash

# install k3d 3.0.0
curl -s https://raw.githubusercontent.com/rancher/k3d/master/install.sh | bash

k3d cluster delete greymatter

k3d cluster create greymatter -a 4 --api-port 30000 && sleep 10
export KUBECONFIG="$(k3d kubeconfig get greymatter)"
echo "Cluster is connected"
