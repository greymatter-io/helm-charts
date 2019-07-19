# Documentation

## TL;DR;

```console
$ helm install documentation
```

## Introduction

This chart bootstraps an documentation deployment on a [Kubernetes](http://kubernetes.io) or [OpenShift](https://www.openshift.com/) cluster using the [Helm](https://helm.sh) package manager.

## Installing the Chart

To install the chart with the release name `<my-release>`:

```console
$ helm install documentation --name <my-release>
```

The command deploys documentation on the cluster in the default configuration. The [configuration](#configuration) section lists the parameters that can be configured during installation.

## Uninstalling the Chart

To uninstall/delete the `<my-release>` deployment:

```console
$ helm delete <my-release>
```

The command removes all components associated with the chart and deletes the release.

## Configuration

The following tables list the configurable parameters of the documentation chart and their default values.

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

### Service Configuration

| Parameter                     | Description | Default                                                                 |
| ----------------------------- | ----------- | ----------------------------------------------------------------------- |
| documentation.name            |             | documentation                                                           |
| documentation.base_path       |             | "services/documentation/3.0.0/"                                         |
| documentation.version         |             | 3.0.0                                                                   |
| documentation.image           |             | "docker.production.deciphernow.com/deciphernow/gm-documentation:v3.0.0" |
| documentation.imagePullPolicy |             | Always                                                                  |

Environment variables set in values.yaml:

| Environment variable | Default                         |
| -------------------- | ------------------------------- |
| base_path            | "services/documentation/3.0.0/" |
| ingres_ca_cert_path  | 'Setup,FAQ'                     |

### Sidecar Configuration

| Parameter                         | Description | Default                                                       |
| --------------------------------- | ----------- | ------------------------------------------------------------- |
| sidecar.version                   |             | 0.8.0                                                         |
| sidecar.image                     |             | docker.production.deciphernow.com/deciphernow/gm-proxy:0.8.0' |
| sidecar.imagePullPolicy           |             | Always                                                        |
| sidecar.resources.limits.cpu      |             | 200m                                                          |
| sidecar.resources.limits.memory   |             | 4Gi                                                           |
| sidecar.resources.requests.cpu    |             | 1                                                             |
| sidecar.resources.requests.memory |             | 2Gi                                                           |
| sidecar.create_sidecar_secret     |             | false                                                         |
| sidecar.certificates              |             | Set in values.yaml                                            |

### Sidecar Environment Variable Configuration

| Environment Variable | Default          |
| -------------------- | ---------------- |
| service_port         | 8080             |
| service_host         | 127.0.0.1        |
| kafka_topic          | gm-documentation |
| port                 | 9080             |

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

- All the files listed under this variable will overwrite any existing files by the same name in the documentation config directory.
- Files not mentioned under this variable will remain unaffected.

```console
$ helm install documentation --name <my-release> \
  --set=jwt.version=v0.2.0, sidecar.ingress_use_tls='false'
```

Alternatively, a YAML file that specifies the values for the above parameters can be provided while installing the chart. For example :

```console
$ helm install documentation --name <my-release> -f custom.yaml
```
