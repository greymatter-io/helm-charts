# JWT

## TL;DR;

```console
$ helm install jwt
```

## Introduction

This chart bootstraps an jwt deployment on a [Kubernetes](http://kubernetes.io) or [OpenShift](https://www.openshift.com/) cluster using the [Helm](https://helm.sh) package manager.

## Installing the Chart

To install the chart with the release name `<my-release>`:

```console
$ helm install jwt --name <my-release>
```

The command deploys jwt on the cluster in the default configuration. The [configuration](#configuration) section lists the parameters that can be configured during installation.

## Uninstalling the Chart

To uninstall/delete the `<my-release>` deployment:

```console
$ helm delete <my-release>
```

The command removes all components associated with the chart and deletes the release.

## Configuration

The following tables list the configurable parameters of the jwt chart and their default values.

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

| Parameter                       | Description | Default                                                                                                                                           |
| ------------------------------- | ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| jwt.version                     |             | 0.2.0                                                                                                                                             |
| jwt.image                       |             |                                                                                                                                                   |
| jwt.command                     |             | ['/bin/sh']                                                                                                                                       |
| jwt.args                        |             | ['-c','if [[ ! -d ./certs ]]; then mkdir -p ./certs; fi && if [[ ! -d ./etc ]]; then mkdir -p ./certs; fi && /gm-jwt-security/gm-jwt-security',,] |
| jwt.redis_db                    |             | '0'                                                                                                                                               |
| jwt.redis_pass                  |             | redis                                                                                                                                             |
| jwt.base_pass                   |             | /services/jwt-security/0.2.0                                                                                                                      |
| jwt.egress_use_tls              |             | 'true'                                                                                                                                            |
| jwt.users_mount_point           |             | /gm-jwt-security/etc                                                                                                                              |
| jwt.certs_mount_point           |             | /gm-jwt-security/certs                                                                                                                            |
| jwt.imagePullPolicy             |             | Always                                                                                                                                            |
| jwt.rescources.limits.cpu       |             | 200m                                                                                                                                              |
| jwt.rescources.limits.memory    |             | 512Mi                                                                                                                                             |
| jwt.resources.requests.cpu      |             | 100m                                                                                                                                              |
| jwt.resources.requests.memory   |             | 64Mi                                                                                                                                              |
| jwt.envars                      |             | See jwt/values.yaml                                                                                                                               |
| jwt.secrets                     |             | See jwt/values.yaml                                                                                                                               |
| jwt.users                       |             | See jwt/values.yaml                                                                                                                               |
|                                 |             |                                                                                                                                                   |
| redis.secret_name               |             | redis-password                                                                                                                                    |
| redis.password                  |             | 'password'                                                                                                                                        |
| redis.openshift.image           |             | 'centos/redis-32-centos7'                                                                                                                         |
| redis.k8s.image                 |             | 'redis:3.2'                                                                                                                                       |
| redis.replica_count             |             | 1                                                                                                                                                 |
| redis.imagePullPolicy           |             | Always                                                                                                                                            |
| redis.resources.limits.cpu      |             | 200m                                                                                                                                              |
| redis.resources.limits.memory   |             | 500Mi                                                                                                                                             |
| redis.resources.requests.cpu    |             | 100m                                                                                                                                              |
| redis.resources.requests.memory |             | 128Mi                                                                                                                                             |

### Sidecar Configuration

| Parameter                     | Description       | Default                                                                                 |
| ----------------------------- | ----------------- | --------------------------------------------------------------------------------------- |
| sidecar.image                 | Proxy Image       | 'docker.production.deciphernow.com/deciphernow/gm-proxy:{{ $.Values.sidecar.version }}' |
| sidecar.proxy_dynamic         |                   | 'true'                                                                                  |
| sidecar.metrics_key_function  |                   | depth                                                                                   |
| sidecar.ingress_use_tls       | Enable TLS        | 'true'                                                                                  |
| sidecar.imagePullPolicy       | Image pull policy | Always                                                                                  |
| sidecar.create_sidecar_secret | Create Certs      | false                                                                                   |
| sidecar.certificates          |                   | {name:{ca: ... , cert: ... , key ...}}                                                  |

### Sidecar Environment Variable Configuration

| Environment Variable | Default                           |
| -------------------- | --------------------------------- |
| egress_use_tls       | {{ .Values.jwt.egress_use_tls }}  |
| egress_ca_cert_path  | /etc/proxy/tls/sidecar/ca.crt     |
| egress_cert_path     | /etc/proxy/tls/sidecar/server.crt |
| egress_key_path      | /etc/proxy/tls/sidecar/server.key |
| port                 | 8080                              |
| service_host         | 127.0.0.1                         |
| service_port         | 3000                              |

### Details

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

- All the files listed under this variable will overwrite any existing files by the same name in the jwt config directory.
- Files not mentioned under this variable will remain unaffected.

```console
$ helm install jwt --name <my-release> \
  --set=jwt.version=v0.2.0, sidecar.ingress_use_tls='false'
```

Alternatively, a YAML file that specifies the values for the above parameters can be provided while installing the chart. For example :

```console
$ helm install jwt --name <my-release> -f custom.yaml
```
