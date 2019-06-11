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

## Configuration

The following table lists the configurable parameters of the edge chart and their default values.

### Ingress Configuration

| Parameter                                | Description | Default                     |
| ---------------------------------------- | ----------- | --------------------------- |
| ingress_config.environment               |             | kubernetes                  |
| ingress_config.domain                    |             | development.deciphernow.com |
| ingress_config.route_url_name            |             | greymatter                  |
| ingress_config.remove_namespace_from_url |             | 'false'                     |
|                                          |             |                             |

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

## Additional Configurations

| Parameter          | Description        | Default    |
| ------------------ | ------------------ | ---------- |
| xds.port           | xDS Port           | 18000      |
| xds.cluster        | xDS Cluster        | greymatter |
|                    |                    |            |
| exhibitor.replicas | Exhibitor Replicas | 1          |

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
