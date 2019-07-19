# SLO

## TL;DR;

```console
$ helm install slo
```

## Introduction

This chart bootstraps an slo deployment on a [Kubernetes](http://kubernetes.io) or [OpenShift](https://www.openshift.com/) cluster using the [Helm](https://helm.sh) package manager.

## Installing the Chart

To install the chart with the release name `<my-release>`:

```console
$ helm install slo --name <my-release>
```

The command deploys slo on the cluster in the default configuration. The [configuration](#configuration) section lists the parameters that can be configured during installation.

## Uninstalling the Chart

To uninstall/delete the `<my-release>` deployment:

```console
$ helm delete <my-release>
```

The command removes all components associated with the chart and deletes the release.

## Configuration

The following tables list the configurable parameters of the slo chart and their default values.

### Global Configuration

| Parameter                        | Description | Default    |
| -------------------------------- | ----------- | ---------- |
| global.environment               |             | kubernetes |
| global.domain                    |             |            |
| global.route_url_name            |             |            |
| global.remove_namespace_from_url |             |            |
| global.exhibitor.replicas        |             | 1          |
| global.xds.port                  |             | 18000      |
| global.xds.cluster               |             | greymatter |

### Service Configuration

| Parameter                          | Description | Default                                                    |
| ---------------------------------- | ----------- | ---------------------------------------------------------- |
| slo.version                        |             | 0.4.0                                                      |
| slo.image                          |             | docker.production.deciphernow.com/deciphernow/gm-slo:0.4.0 |
| slo.imagePullPolicy                |             | Always                                                     |
| slo.resources.limits.cpu           |             | 250m                                                       |
| slo.resources.limits.memory        |             | 512Mi                                                      |
| slo.resources.requests.cpu         |             | 100m                                                       |
| slo.resources.requests.memory      |             | 128Mi                                                      |
|                                    |             |                                                            |
| postgres.data_mount_point          |             | /var/lib/pgsql/data                                        |
| postgres.openshift.image           |             | 'docker.io/centos/postgresql-95-centos7:9.5'               |
| postgres.k8s.image                 |             | 'postgres:9.5'                                             |
| postgres.imagePullPolicy           |             | Always                                                     |
| postgres.replica_count             |             | 1                                                          |
| postgres.resources.limits.cpu      |             | 200m                                                       |
| postgres.resources.limits.memory   |             | 512Mi                                                      |
| postgres.resources.requests.cpu    |             | 100m                                                       |
| postgres.resources.requests.memory |             | 128Mi                                                      |
| postgres.credentials.secret_name   |             | postgres-credentials                                       |
| postgres.credentials.username      |             | greymatter                                                 |
| postgres.credentials.password      |             | greymatter                                                 |
| postgres.credentials.database      |             | greymatter                                                 |
| postgres.ssl.enabled               |             | false                                                      |
| postgres.ssl.name                  |             | postgres-ssl-certs                                         |
| postgres.ssl.mount_path            |             | /secret/cert                                               |
| postgres.certificates              |             | See slo/values.yaml                                        |
| postgres.envvars                   |             | See slo/values.yaml                                        |

### Sidecar Configuration

| Parameter                         | Description       | Default                                                                                 |
| --------------------------------- | ----------------- | --------------------------------------------------------------------------------------- |
| sidecar.version                   | Proxy Version     | 0.8.0                                                                                   |
| sidecar.image                     | Proxy Image       | 'docker.production.deciphernow.com/deciphernow/gm-proxy:{{ $.Values.sidecar.version }}' |
| sidecar.imagePullPolicy           | Image pull policy | Always                                                                                  |
| sidecar.create_sidecar_secret     | Create Certs      | false                                                                                   |
| sidecar.certificates              |                   | {name:{ca: ... , cert: ... , key ...}}                                                  |
| sidecar.resources.limits.cpu      |                   | 200m                                                                                    |
| sidecar.resources.limits.memory   |                   | 512Mi                                                                                   |
| sidecar.resources.requests.cpu    |                   | 100m                                                                                    |
| sidecar.resources.requests.memory |                   | 128Mi                                                                                   |

### Sidecar Environment Variable Configuration

| Environment Variable | Default |
| -------------------- | ------- |
| port                 | 8080    |
| service_port         | 1337    |
| kafka_topic          | gm-slo  |

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

- All the files listed under this variable will overwrite any existing files by the same name in the slo config directory.
- Files not mentioned under this variable will remain unaffected.

```console
$ helm install slo --name <my-release> \
  --set=jwt.version=v0.2.0, sidecar.ingress_use_tls='false'
```

Alternatively, a YAML file that specifies the values for the above parameters can be provided while installing the chart. For example :

```console
$ helm install slo --name <my-release> -f custom.yaml
```
