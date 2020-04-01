#!/bin/bash

# install k3d 1.3.4
curl -s https://raw.githubusercontent.com/rancher/k3d/master/install.sh | TAG=v1.3.4 bash

k3d create --workers 4 --name greymatter
export KUBECONFIG="$(k3d get-kubeconfig --name='greymatter')"