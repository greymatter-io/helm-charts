# GM-data

## TL;DR;

```console
$ helm install data
```

## Introduction

This chart bootstraps a data deployment on a [Kubernetes](http://kubernetes.io) or [OpenShift](https://www.openshift.com/) cluster using the [Helm](https://helm.sh) package manager.

## Installing the Chart

To install the chart with the release name `<my-release>`:

```console
$ helm install data --name <my-release>
```

The command deploys data on the cluster in the default configuration. The [configuration](#configuration) section lists the parameters that can be configured during installation.

## Uninstalling the Chart

To uninstall/delete the `<my-release>` deployment:

```console
$ helm delete <my-release>
```

The command removes all components associated with the chart and deletes the release.

## Configuration

The following tables list the configurable parameters of the data chart and their default values.

### Global Configuration

| Parameter                        | Description       | Default    |
| -------------------------------- | ----------------- | ---------- |
| global.environment               |                   | kubernetes |
| global.domain                    | edge-ingress.yaml |            |
| global.route_url_name            | edge-ingress.yaml |            |
| global.remove_namespace_from_url | edge-ingress.yaml | ''         |
| global.exhibitor.replicas        |                   | 1          |
| global.xds.port                  |                   | 18000      |
| global.xds.cluster               |                   | greymatter |

### Service Configuration

| Parameter                          | Description | Default                                                     |
| ---------------------------------- | ----------- | ----------------------------------------------------------- |
| data.version                       |             | 0.2.3                                                       |
| data.client_jwt_endpoint_address   |             | localhost                                                   |
| data.client_jwt_endpoint_use_tls   |             | 'true'                                                      |
| data.base_path                     |             | /services/data/0.2.3                                        |
| data.image                         |             | docker.production.deciphernow.com/deciphernow/gm-data:0.2.3 |
| data.certs_mount_point             |             | /certs                                                      |
| data.imagePullPolicy               |             | Always                                                      |
| data.use_tls                       |             | true                                                        |
| data.master_key                    |             | ac8923[lkn43589vi23kl4rfgv0ws                               |
| data.aws.access_key                |             |                                                             |
| data.aws.secret_key                |             |                                                             |
| data.aws.region                    |             |                                                             |
| data.aws.bucket                    |             |                                                             |
| data.resources.limits.cpu          |             | 250m                                                        |
| data.resources.limits.memory       |             | 512Mi                                                       |
| data.resources.requests.cpu        |             | 100m                                                        |
| data.rsources.requests.memory      |             | 128Mi                                                       |
| data.mongo.replicas                |             | 1                                                           |
| data.mongo.image                   |             | 'deciphernow/mongo:4.0.3'                                   |
| data.mongo.imagePullPolicy         |             | Always                                                      |
| data.mongo.pvc_size                |             | 40                                                          |
| data.mongo.resources.limits.cpu    |             | 200m                                                        |
| data.mongo.resources.limits.memory |             | 512Mi                                                       |
| data.mongo.resources.requests      |             | 100m                                                        |
| data.mongo.resources.memory        |             | 128Mi                                                       |
| data.credentials.secret_name       |             | 'mongo-credentials'                                         |
| data.credentials.root_username     |             | 'mongo'                                                     |
| data.credentials.root_password     |             | 'mongo'                                                     |
| data.credentials.database          |             | 'gmdata'                                                    |
| data.admin_password                |             | 'mongopassword'                                             |
| data.ssl.enabled                   |             | false                                                       |
| data.ssl.name                      |             | mongo-ssl-certs                                             |
| data.ssl.mount_path                |             | /secret/cert                                                |
| data.certificates.ca               |             | {...}                                                       |
| data.certificates.cert             |             | {...}                                                       |
| data.certificates.key              |             | {...}                                                       |
| data.certificates.cert_key         |             | {...}                                                       |

## Sidecar Configuration

| Parameter                         | Description       | Default                                                                                 |
| --------------------------------- | ----------------- | --------------------------------------------------------------------------------------- |
| sidecar.version                   | Proxy Version     | 0.8.0                                                                                   |
| sidecar.image                     | Proxy Image       | 'docker.production.deciphernow.com/deciphernow/gm-proxy:{{ $.Values.sidecar.version }}' |
| sidecar.proxy_dynamic             |                   | 'true'                                                                                  |
| sidecar.metrics_key_function      |                   | depth                                                                                   |
| sidecar.ingress_use_tls           | Enable TLS        | 'true'                                                                                  |
| sidecar.imagePullPolicy           | Image pull policy | Always                                                                                  |
| sidecar.create_sidecar_secret     | Create Certs      | false                                                                                   |
| sidecar.certificates              |                   | {name:{ca: ... , cert: ... , key ...}}                                                  |
| sidecar.resources.limits.cpu      |                   | 200m                                                                                    |
| sidecar.resources.limits.memory   |                   | 512Mi                                                                                   |
| sidecar.resources.requests.cpu    |                   | 100m                                                                                    |
| sidecar.resources.requests.memory |                   | 128Mi                                                                                   |

## Sidecar Environment Variable Configuration

| Environment Variable | Default                           |
| -------------------- | --------------------------------- |
| egress_use_tls       | {{ .Values.data.use_tls }}        |
| egress_ca_cert_path  | /etc/proxy/tls/sidecar/ca.crt     |
| egress_cert_path     | /etc/proxy/tls/sidecar/server.crt |
| egress_key_path      | /etc/proxy/tls/sidecar/server.key |
| port                 | 8080                              |
| service_port         | 8181                              |

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

- All the files listed under this variable will overwrite any existing files by the same name in the data config directory.
- Files not mentioned under this variable will remain unaffected.

```console
$ helm install data --name <my-release> \
  --set=jwt.version=v0.2.0, sidecar.ingress_use_tls='false'
```

Alternatively, a YAML file that specifies the values for the above parameters can be provided while installing the chart. For example :

```console
$ helm install data --name <my-release> -f custom.yaml
```
