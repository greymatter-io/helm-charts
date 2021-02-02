#!/bin/bash

k3d cluster delete greymatter 
make k3d
export KUBECONFIG=~/.k3d/kubeconfig-greymatter.yaml
make secrets install
