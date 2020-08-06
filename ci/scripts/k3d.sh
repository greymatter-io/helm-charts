#!/bin/bash

# install k3d 3.0.0
NAME=greymatter

if ! command -v k3d &> /dev/null
then
    echo "*** k3d must be installed to start a kubernetes cluster with k3d. Install here: https://k3d.io/#installation ***"
    exit
fi

output=$(k3d --version)
len=${#output}
version=${output:13:1}
default="3"

if ((version < default)); 
    then
        echo '***Please update k3d to v3.0.0 or greater***'
        exit
fi
 

k3d cluster create $NAME -a 4 -p 30000:10808@loadbalancer && sleep 10

export KUBECONFIG=$(k3d kubeconfig write greymatter)

echo "Cluster is connected"

echo -e "\nSet KUBECONFIG in your shell by running:"
echo -e "export KUBECONFIG=$(k3d kubeconfig write greymatter)"