# Ingress

- [Set the ingress URL](#set-the-ingress-url)
- [Set up ingress](#set-up-ingress)
  - [Kubernetes](#kubernetes)
    - [With Voyager](#with-voyager)
    - [With Nginx Ingress Controller](#with-nginx-ingress-controller)
    - [With another Ingress Controller](#with-another-ingress-controller)
  - [OpenShift](#openshift)

>Grey Matter requires that the Edge service perform TLS termination.  Therefore, any ingress options need to be configured for TLS passthrough.

By default, your cluster is not accessible from the outside world. However, the Charts offer ingress options for both Kubernetes and OpenShift.  When deploying to an OpenShift cluster, the charts will use the native OpenShift [Routes](https://docs.openshift.com/container-platform/3.9/architecture/networking/routes.html)

For Kubernetes, your options are a little more plentiful.  By default, the Grey Matter Helm Charts will expect to use a [Voyager](https://appscode.com/products/voyager/) ingress.  However, these options can be easily updated to support other ingress controllers.  These values can be updated at `.edge.ingress` in the `greymatter.yaml` file.

Take a look at the [edge chart documentation](../edge/README.md) for implementation details on how the Grey Matter ingress sidecar is exposed in both Kubernetes and OpenShift.

## Set the ingress URL

By default, our Helm charts will deploy edge with an ingress URL of `<route_url_name>.<namespace>.<domain>`. If you would like to deploy it without the namespace as part of the url you will need to set `remove_namespace_from_url` to `true` in `greymatter.yaml`. This will result in the url being set to `<route_url_name>.<domain>`.

*NOTE: For OpenShift, make sure you choose a unique `route_url_name`.*

## Set up ingress

### Kubernetes

#### With Voyager

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

#### With Nginx Ingress Controller

If you choose to use the Nginx Ingress Controller, you need to ensure it is installed to allow SSL passthrough. The default installation of the Nginx Ingress Controller does not deploy nginx with SSL passthrough enabled. The Nginx Ingress [documentation](https://kubernetes.github.io/ingress-nginx/user-guide/tls/#ssl-passthrough) provides instructions for enabling SSL passthrough.

If using AWS, we recommend using an NLB for external traffic managmenet to the Nginx Controller. The NLB is a simple appliance and requires less configuration for Grey Matter than ELBs or ALBs.  AWS has [documentation](https://aws.amazon.com/blogs/opensource/network-load-balancer-nginx-ingress-controller-eks/) for this setup that is extremely helpful, but don't be nervous that they use AWS EKS; the same configuration can work in any Kubernetes deployed in AWS.

Updates will be needed to the `greymatter.yaml` file to provide a new configuration for the edge ingress.  Below is an Nginx Ingress example that can be used

```yaml
edge:
  ingress:
    apiVersion: extensions/v1beta1
    annotations:
      nginx.ingress.kubernetes.io/ssl-passthrough: "true"
      nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
      nginx.ingress.kubernetes.io/backend-protocol: "https"

    rules:
      - host: greymatter.development.deciphernow.com
        http:
          paths:
            - path: /
              backend:
                serviceName: edge
                servicePort: 8080
```

This configuration routes SSL traffic to the Grey Matter Edge sidecar, indicated by the `edge` service name, running on port 8080.



#### With another Ingress Controller

If you choose to use a different ingress controller, you need to make sure that all of the prerequesites are in place before deploying the Grey Matter Helm Charts.  For instance, if you choose to use the NGINX controller, it must be installed prior to the deploying these charts.

Whichever ingress controller you choose, it needs to allow for SSL passthrough.  

### OpenShift

In OpenShift, ingress is defined as a Route with the URL described above. No additional steps are required as the OpenShift router will automatically handle all traffic for you.
