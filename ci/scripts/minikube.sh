#!/bin/bash

cd $(dirname "${BASH_SOURCE[0]}")

#Determine if we are on AWS or not
MINI='minikube'
curl -m 2 169.254.169.254/latest/meta-data > /dev/null
RC=$?
if [ $RC -ne 0 ]; then
    MINI='sudo /home/ubuntu/bin/minikube' 
fi

$MINI start --memory 6144 --cpus 6
helm init --wait
./ci/scripts/install-voyager.sh
helm install decipher/greymatter -f greymatter.yaml -f greymatter-secrets.yaml -f credentials.yaml --set global.environment=kubernetes --set global.k8s_use_voyager_ingress=true -n gm-deploy
./ci/scripts/show-voyager.sh

