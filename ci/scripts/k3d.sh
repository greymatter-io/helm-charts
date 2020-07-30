#!/bin/bash

# install k3d 3.0.0
NAME=greymatter
curl -s https://raw.githubusercontent.com/rancher/k3d/master/install.sh | bash

k3d cluster delete $NAME

k3d cluster create $NAME -a 4 -p 30000:10808@loadbalancer && sleep 10

#The following two lines set and access the kubeconfig file, respectively
#The former returns the entire config rather than a path, so separating the k3d and export commands is optimal
k3d kubeconfig get $NAME
export KUBECONFIG=$HOME/.k3d/kubeconfig-$NAME.yaml

echo "Cluster is connected"
