export PROVIDER=minikube

.PHONY: voyager
voyager:
	ls
	helm repo add appscode https://charts.appscode.com/stable/
	helm repo update
	helm install voyager-operator appscode/voyager --namespace kube-system --set cloudProvider=minikube --set enableAnalytics=false --set apiserver.enableAdmissionWebhook=false --version v12.0.0-rc.1

.PHONY: remove-voyager
remove-voyager:
	helm uninstall voyager-operator --namespace kube-system