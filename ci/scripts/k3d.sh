#!/bin/bash

# install k3d 3.0.0
NAME=greymatter

if ! command -v k3d &> /dev/null
then
    echo "*** k3d must be installed to start a kubernetes cluster with k3d. Install here: https://k3d.io/#installation ***"
    exit
fi

k3d cluster create $NAME -a 4 -p 30000:10808@loadbalancer && sleep 10

#The following two lines set and access the kubeconfig file, respectively
#The former returns the entire config rather than a path, so separating the k3d and export commands is optimal
k3d kubeconfig get $NAME > /dev/null
export KUBECONFIG=$HOME/.k3d/kubeconfig-$NAME.yaml

echo "Cluster is connected"

echo -e "\nSet KUBECONFIG in your shell by running:"
echo -e "export KUBECONFIG=$$HOME/.k3d/kubeconfig-$$NAME.yaml"

K3D=true
export K3d