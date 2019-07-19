# Dashboard

## TL;DR;

```console
$ helm install dashboard
```

## Introduction

This chart bootstraps a dashboard deployment on a [Kubernetes](http://kubernetes.io) or [OpenShift](https://www.openshift.com/) cluster using the [Helm](https://helm.sh) package manager.

## Installing the Chart

To install the chart with the release name `<my-release>`:

```console
$ helm install dashboard --name <my-release>
```

The command deploys dashboard on the cluster in the default configuration. The [configuration](#configuration) section lists the parameters that can be configured during installation.

## Uninstalling the Chart

To uninstall/delete the `<my-release>` deployment:

```console
$ helm delete <my-release>
```

The command removes all components associated with the chart and deletes the release.

## Configuration

The following tables list the configurable parameters of the dashboard chart and their default values.

### Global Configuration

| Parameter                        | Description       | Default    |
| -------------------------------- | ----------------- | ---------- |
| global.environment               |                   |            |
| global.domain                    | edge-ingress.yaml |            |
| global.route_url_name            | edge-ingress.yaml |            |
| global.remove_namespace_from_url | edge-ingress.yaml | ''         |
| global.exhibitor.replicas        |                   | 1          |
| global.xds.port                  |                   | 18000      |
| global.xds.cluster               |                   | greymatter |

### Dashboard

#### Service Configuration

| Parameter                           | Description           | Default                                                            |
| ----------------------------------- | --------------------- | ------------------------------------------------------------------ |
| dashboard.image                     | Docker Image          | 'docker.production.deciphernow.com/deciphernow/gm-dashboard:2.5.0' |
| dashboard.fabric_server             | Path to fabric server | '/services/catalog/0.3.6/'                                         |
| dashboard.use_prometheus            |                       | 'true'                                                             |
| dashboard.prometheus_server         |                       | '/services/prometheus/2.7.1/api/v1/'                               |
| dashboard.objectives_server         |                       | '/services/slo/0.4.0/'                                             |
| dashboard.base_path                 |                       | '/services/dashboard/latest'                                       |
| dashboard.version                   |                       | latest                                                             |
| dashboard.imagePullPolicy           |                       | Always                                                             |
| dashboard.resources.limits.cpu      |                       | 200m                                                               |
| dashboard.resources.limits.memory   |                       | 1Gi                                                                |
| dashboard.resources.requests.cpu    |                       | 100m                                                               |
| dashboard.resources.requests.memory |                       | 128Mi                                                              |

#### Sidecar Configuration

| Parameter                     | Description       | Default                                                                                 |
| ----------------------------- | ----------------- | --------------------------------------------------------------------------------------- |
| sidecar.version               | Proxy Version     | 0.8.0                                                                                   |
| sidecar.image                 | Proxy Image       | 'docker.production.deciphernow.com/deciphernow/gm-proxy:{{ $.Values.sidecar.version }}' |
| sidecar.imagePullPolicy       | Image pull policy | Always                                                                                  |
| sidecar.create_sidecar_secret | Create Certs      | false                                                                                   |
| sidecar.certificates          |                   | {name:{ca: ... , cert: ... , key ...}}                                                  |

#### Sidecar Environment Variables

| Environment variable | Default                             |
| -------------------- | ----------------------------------- |
| ingress_use_tls      | 'true'                              |
| ingress_ca_cert_path | '/etc/proxy/tls/sidecar/ca.crt'     |
| ingress_cert_path    | '/etc/proxy/tls/sidecar/server.crt' |
| ingress_key_path     | '/etc/proxy/tls/sidecar/server.key' |
| metrics_port         | '8081                               |
| port                 | '8080'                              |
| metrics_key_function | 'depth'                             |
| proxy_dynamic        | 'true'                              |
| service_host         | 127.0.0.1                           |
| service_port         | 1337                                |
| obs_enabled          | 'false'                             |
| obs_enforce          | 'false'                             |
| obs_full_response    | 'false'                             |

### Prometheus

#### Service Configuration

| Parameter                     | Description | Default                      |
| ----------------------------- | ----------- | ---------------------------- |
| prometheus.image              |             | 'prom/prometheus:v2.7.1'     |
| prometheus.imagePullPolicy    |             | Always                       |
| prometheus.zk_announce_path   |             | '/services/prometheus/2.7.1' |
| prometheus.replica_count      |             | 1                            |
| prometheus.data_mount_point   |             | /var/lib/prometheus/data     |
| prometheus.config_mount_point |             | /etc/prometheus              |
| prometheus.start_cmd          |             | /bin/prometheus              |
| prometheus.limit.cpu          |             | 1                            |
| prometheus.limit.memory       |             | 2Gi                          |
| prometheus.request.cpu        |             | 500m                         |
| prometheus.request.memory     |             | 256Mi                        |

#### Sidecar Configuration

| Parameter                                | Description       | Default                                                        |
| ---------------------------------------- | ----------------- | -------------------------------------------------------------- |
| sidecar_prometheus.version               | Proxy Version     | 0.8.0                                                          |
| sidecar_prometheus.image                 | Proxy Image       | 'docker.production.deciphernow.com/deciphernow/gm-proxy:{{ $.Values.sidecar.version }}' |
| sidecar_prometheus.imagePullPolicy       | Image pull policy | Always                                                         |
| sidecar_prometheus.create_sidecar_secret | Create Certs      | false                                                          |
| sidecar_prometheus.certificates          |                   | {name:{ca: ... , cert: ... , key ...}}                         |

#### Sidecar Environment Variables

| Environment variable | Default                             |
| -------------------- | ----------------------------------- |
| ingress_use_tls      | 'true'                              |
| ingress_ca_cert_path | '/etc/proxy/tls/sidecar/ca.crt'     |
| ingress_cert_path    | '/etc/proxy/tls/sidecar/server.crt' |
| ingress_key_path     | '/etc/proxy/tls/sidecar/server.key' |
| metrics_port         | '8081                               |
| port                 | '8080'                              |
| metrics_key_function | 'depth'                             |
| proxy_dynamic        | 'true'                              |
| service_host         | 127.0.0.1                           |
| service_port         | 9090                                |
| obs_enabled          | 'false'                             |
| obs_enforce          | 'false'                             |
| obs_full_response    | 'false'                             |

### Sidecar Environment Variable Configuration

| Environment Variable | Default |
| -------------------- | ------: |
| port                 |    8080 |
| service_port         |    1337 |

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

- All the files listed under this variable will overwrite any existing files by the same name in the dashboard config directory.
- Files not mentioned under this variable will remain unaffected.

```console
$ helm install dashboard --name <my-release> \
  --set=jwt.version=v0.2.0, sidecar.ingress_use_tls='false'
```

Alternatively, a YAML file that specifies the values for the above parameters can be provided while installing the chart. For example :

```console
$ helm install dashboard --name <my-release> -f custom.yaml
```
