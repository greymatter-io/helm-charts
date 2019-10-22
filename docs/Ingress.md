# Ingress

How to make the cluster accessible from the internet.

Take a look at the `edge` chart documentation for the implementation details on how Grey Matter is exposed to the internet in both OpenShift and Kubernetes environments.

For Kubernetes, you need to take some additional steps to install Voyager, the ingress controller we use. For OpenShift, we use their `Route`s, which are effectively the same as Kubernetes ingresses.

To view the provisioned loadbalancer (if using a cloud provider), run:

```sh
kubectl get ing.voy
```

## How to set your ingress URL

By default Helm will deploy edge with an ingress URL of `<route_url_name>.<namespace>.<domain>`. If you would like to deploy it without the namespace as part of the url you will need to set `remove_namespace_from_url` to `'true'`. This will result in the url being set to `<route_url_name>.<domain>`. NOTE: make sure you choose a unique `route_url_name` in the OpenShift environment.

## Setting up the Ingress

In OpenShift environments, the ingress is defined as a Route with the ingress URL describes above. This should mean that you need no additional installation steps and the OpenShift router should handle it all for you.

In Kubernetes environments however, the user must take a few additional steps to install [Voyager](https://appscode.com/products/voyager/), a [HAProxy](http://www.haproxy.org/) based ingress controller which forwards TCP requests from the LoadBalancer in your cloud environment to the `edge` service.
Initially, we used [`ingress-nginx`](https://github.com/kubernetes/ingress-nginx), which is probably the most commonly known Kubernetes ingress controller.

However, it for some reason still tried to decode and convert the TLS certs even when ["SSL passthrough"](https://kubernetes.github.io/ingress-nginx/user-guide/tls/#ssl-passthrough) was enabled.
This was giving us some pretty cryptic errors, so we decided to just use a L4 TCP proxy that would proxy the entire connection and wouldn't care about TLS. We decided on Voyager, a Kubernetes Ingress controller built on top of HAProxy, mainly for its ease of use and existing integrations with major cloud providers. These integrations are what allow the automatic provisioning of real cloud load balancers from the Kubernetes created `LoadBalancer` resources.

At this writing there is [an issue](https://github.com/appscode/voyager/issues/1415) specifying voyager ingress as a dependency, so we need to manually configure Voyager ingress locally before launching our Grey Matter cluster. This can be done with following commands:

```sh
export PROVIDER=minikube
helm repo add appscode https://charts.appscode.com/stable/
helm repo update
helm install appscode/voyager --name voyager-operator --version 10.0.0 \
  --namespace kube-system \
  --set cloudProvider=$PROVIDER \
  --set enableAnalytics=false \
  --set apiserver.enableAdmissionWebhook=false
...
NOTES:
Set cloudProvider for installing Voyager

To verify that Voyager has started, run:

  kubectl --namespace=kube-system get deployments -l "release=voyager-operator, app=voyager"
```

Now you're all set. When you deploy the edge service, voyager-operator will create a custom `Ingress` resource which will provision a load balancer for you. You can run `kubectl get svc voyager-edge` to see the cluster ip and port.
