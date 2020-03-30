helm dep up data
helm dep up fabric
helm dep up sense

helm install secrets secrets -f credentials.yaml

helm install voyager-operator appscode/voyager \
    --version v12.0.0-rc.0 \
    --namespace kube-system \
    --set cloudProvider=minikube

while [[ $(kubectl get pods -n kube-system -l app=voyager -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do
    echo "waiting for pod" && sleep 10
done

helm install edge edge --set=global.environment=kubernetes

helm install fabric fabric --set=global.environment=kubernetes

helm install data data --set=global.environment=kubernetes --set=global.waiter.service_account.create=false

helm install sense sense --set=global.environment=kubernetes --set=global.waiter.service_account.create=false
