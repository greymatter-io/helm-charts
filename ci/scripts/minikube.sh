#!/bin/bash

cd $(dirname "${BASH_SOURCE[0]}")/../..

unset KUBECONFIG

MINI=minikube
# Determine if we are on AWS or not
LC=$(curl -s -m 2 169.254.169.254/latest/meta-data | wc -l )
if [ $LC -ge 4 ]; then
    minikube config set vm-driver none
    MINILOC=$(which minikube)
    MINI="sudo $MINILOC"
fi

$MINI start --memory 6144 --cpus 6

if [ $LC -ge 4 ]; then
    sudo chown -R ubuntu /home/ubuntu/.kube /home/ubuntu/.minikube
fi

