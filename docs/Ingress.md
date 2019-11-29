# Ingress

- [Set the ingress URL](#set-the-ingress-url)
- [Set up ingress](#set-up-ingress)
  - [Kubernetes](#kubernetes)
  - [OpenShift](#openshift)
- [Other ingress](#other-ingress)
  - [Nginx](#nginx)

By default, your cluster is not accessible from the outside world. Grey Matter supports two ingress configurations out of the box, Kubernetes with [Voyager](https://appscode.com/products/voyager/) and OpenShift [Routes](https://docs.openshift.com/container-platform/3.9/architecture/networking/routes.html). Both are configured as [TCP passthroughs](https://docs.openshift.com/container-platform/3.9/architecture/networking/routes.html#secured-routes) which send encrypted traffic straight to the Grey Matter ingress sidecar to provide TLS termination. This ingress sidecar is the same sidecar used throughout the mesh; it's role is to only handle edge traffic.

Take a look at the [edge chart documentation](../edge/README.md) for implementation details on how the Grey Matter ingress sidecar is exposed in both Kubernetes and OpenShift.

## Set the ingress URL

By default, our Helm charts will deploy edge with an ingress URL of `<route_url_name>.<namespace>.<domain>`. If you would like to deploy it without the namespace as part of the url you will need to set `remove_namespace_from_url` to `true` in `greymatter.yaml`. This will result in the url being set to `<route_url_name>.<domain>`.

*NOTE: For OpenShift, make sure you choose a unique `route_url_name`.*

## Set up ingress

### Kubernetes

As of this writing, there is [an issue](https://github.com/appscode/voyager/issues/1415) specifying Voyager ingress as a dependency, so we need to manually configure it locally before launching our Grey Matter cluster. In the below commands, set `PROVIDER` to the appropriate [cluster provider](https://appscode.com/products/voyager/v11.0.1/setup/install/) for your environment before running. Then run the commands:

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

Now you're all set. When you deploy the Edge service, the voyager-operator will create a custom `Ingress` resource. For Kubernetes, a [NodePort](https://kubernetes.io/docs/concepts/services-networking/service/#nodeport) service type will be deployed, which exposes the service on the edge node's IP and static port. For, the EKS cloud provider, a [LoadBalancer](https://kubernetes.io/docs/concepts/services-networking/service/#loadbalancer) service type will expose the service using EKS's load balancer. You can run `kubectl get svc voyager-edge` to see the cluster IP and port.

### OpenShift

In OpenShift, ingress is defined as a Route with the URL described above. No additional steps are required as the OpenShift router will automatically handle all traffic for you.

## Other ingress

### Nginx

Another popular ingress controller is [ingress-nginx](https://kubernetes.github.io/ingress-nginx/deploy/) which can also be configured as a passthrough to the Grey Matter ingress sidecar. You can setup Nginx ingress using the following YAML:

```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: gm-ingress-test
  annotations:
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    nginx.ingress.kubernetes.io/ssl-passthrough: "true"
    # nginx.ingress.kubernetes.io/auth-tls-pass-certificate-to-upstream: "true"
  namespace: greymatter
spec:
  rules:
  - host: staging.deciphernow.com
    http:
      paths:
      - backend:
          serviceName: edge
          servicePort: 8080
        path: /
```

This configuration routes SSL traffic to the Grey Matter edge sidecar, indicated by the `edge` service name, running on port 8080. We weren't able to forward user credentials successfully to the edge ingress sidecar, which is why that annotation is currently commented out.
