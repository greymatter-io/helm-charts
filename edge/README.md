# Edge

## TL;DR;

```console
$ helm install edge
```

## Introduction

This chart bootstraps an edge deployment on a [Kubernetes](http://kubernetes.io) or [OpenShift](https://www.openshift.com/) cluster using the [Helm](https://helm.sh) package manager.

## Installing the Chart

To install the chart with the release name `<my-release>`:

```console
$ helm install edge --name <my-release>
```

The command deploys edge on the cluster in the default configuration. The [configuration](#configuration) section lists the parameters that can be configured during installation.

## Uninstalling the Chart

To uninstall/delete the `<my-release>` deployment:

```console
$ helm delete <my-release>
```

The command removes all components associated with the chart and deletes the release.

## How to set your ingress URL

By default Helm will deploy edge with an ingress URL of `<route_url_name>.<namespace>.<domain>`. If you would like to deploy it without the namespace as part of the url you will need to set `remove_namespace_from_url` to `'true'`. This will result in the url being set to `<route_url_name>.<domain>`. NOTE: make sure you choose a unique `route_url_name` in the openshift environment.

## Setting up the Ingress

In openshift environments, the ingress is defined as a Route.

In Kubernetes environments however, the user must take a few additional steps to install [Voyager](https://appscode.com/products/voyager/), a [HAProxy](http://www.haproxy.org/) based ingress controller which forwards TCP requests from the LoadBalancer in your cloud environment to the `edge` service.
Initially, we used [`ingress-nginx`](https://github.com/kubernetes/ingress-nginx), which is probably the most commonly known Kubernetes ingress controller.

However, it for some reason still tried to decode and convert the TLS certs even when ["SSL passthrough"](https://kubernetes.github.io/ingress-nginx/user-guide/tls/#ssl-passthrough) was enabled.
This was giving us some pretty cryptic errors, so we decided to just use a L4 TCP proxy that would proxy the entire connection and wouldn't care about TLS. We decided on Voyager, a Kubernetes Ingress controller built on top of HAProxy, mainly for its ease of use and existing integrations with major cloud providers. These integrations are what allow the automatic provisioning of real cloud load balancers from the Kubernetes created `LoadBalancer` resources. 

We have linked Voyager as a dependency of the `greymatter` helm chart, so it can be configured from your `custom.yaml` file, but can also be installed manually if you would like more flexibility, or to have it be managed as a separate helm release.

We recommend however that you simply configure your `custom.yaml` with your `cloudProvider` and use it as a managed Helm dependency.

### Manual installation
To install Voyager in your environment using helm, set the `$PROVIDER` environment variable to one of the [supported options](https://appscode.com/products/voyager/7.1.1/setup/install/#using-script) (includes acs, aks, aws, azure, baremetal, gce, gke, minikube, and a few more) and run the following commands: 


```sh
helm repo add appscode https://charts.appscode.com/stable/
helm repo update
helm install appscode/voyager --name voyager-operator --version 10.0.0 \
  --namespace kube-system \
  --set cloudProvider=$PROVIDER \
  --set enableAnalytics=false
```

Now you're all set. When you deploy the edge service, it will create an `Ingress` resource which will provision a load balancer for you. If you run `kubectl describe ingresses`, you should be able to see the URL of the endpoint, and connect to it on port 443. TODO: add HTTP forwarding to make all HTTP requests go to HTTPS.

## Configuration

The following tables list the configurable parameters of the edge chart and their default values.

### Global Configuration

| Parameter                        | Description       | Default                     |
| -------------------------------- | ----------------- | --------------------------- |
| global.environment               |                   | kubernetes                  |
| global.domain                    | edge-ingress.yaml | development.deciphernow.com |
| global.route_url_name            | edge-ingress.yaml | greymatter                  |
| global.remove_namespace_from_url | edge-ingress.yaml | 'false'                     |
| global.exhibitor.replicas        |                   | 1                           |
| global.xds.port                  |                   | 18000                       |
| global.xds.cluster               |                   | greymatter                  |

### Service Configuration

| Parameter                      | Description | Default              |
| ------------------------------ | ----------- | -------------------- |
| edge.egress_use_tls            |             | 'true'               |
| edge.inheaders_enabled         |             | 'true'               |
| edge.obs_enabled               |             | 'false'              |
| edge.obs_full_response         |             | 'false'              |
| edge.base_path                 |             | /services/edge/0.7.1 |
| edge.acl_enabled               |             | 'false'              |
| edge.imagePullPolicy           |             | Always               |
| edge.ingress_use_tls           |             | true                 |
| edge.resources.limits.cpu      |             | 1                    |
| edge.resources.limits.memory   |             | 1Gi                  |
| edge.resources.requests.cpu    |             | 100m                 |
| edge.resources.requests.memory |             | 128Mi                |
| edge.create_edge_secret        |             | false                |

### Sidecar Configuration

| Parameter                         | Description       | Default                                                        |
| --------------------------------- | ----------------- | -------------------------------------------------------------- |
| sidecar.version                   | Proxy Version     | 0.7.1                                                          |
| sidecar.image                     | Proxy Image       | 'docker.production.deciphernow.com/deciphernow/gm-proxy:0.7.1' |
| sidecar.proxy_dynamic             |                   | 'true'                                                         |
| sidecar.metrics_key_function      |                   | depth                                                          |
| sidecar.ingress_use_tls           | Enable TLS        | 'true'                                                         |
| sidecar.imagePullPolicy           | Image pull policy | Always                                                         |
| sidecar.create_sidecar_secret     | Create Certs      | false                                                          |
| sidecar.certificates              |                   | {name:{ca: ... , cert: ... , key ...}}                         |
| sidecar.resources.limits.cpu      |                   | 200m                                                           |
| sidecar.resources.limits.memory   |                   | 512Mi                                                          |
| sidecar.resources.requests.cpu    |                   | 100m                                                           |
| sidecar.resources.requests.memory |                   | 128Mi                                                          |
|                                   |                   |                                                                |

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

- All the files listed under this variable will overwrite any existing files by the same name in the edge config directory.
- Files not mentioned under this variable will remain unaffected.

```console
$ helm install edge --name <my-release> \
  --set=jwt.version=v0.2.0, sidecar.ingress_use_tls='false'
```

Alternatively, a YAML file that specifies the values for the above parameters can be provided while installing the chart. For example :

```console
$ helm install edge --name <my-release> -f custom.yaml
```
