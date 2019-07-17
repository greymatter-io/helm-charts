# Greymatter

## TL;DR;

```console
$ helm install greymatter
```

## Introduction

This chart bootstraps an greymatter deployment on a [Kubernetes](http://kubernetes.io) or [OpenShift](https://www.openshift.com/) cluster using the [Helm](https://helm.sh) package manager.

## Installing the Chart

To install the chart with the release name `<my-release>`:

```console
$ helm install greymatter --name <my-release>
```

The command deploys greymatter on the cluster in the default configuration. The [configuration](#configuration) section lists the parameters that can be configured during installation.

## Making the cluster accessible from the internet

Take a look at the `edge` chart documentation for details on how Grey Matter is exposed to the internet in both OpenShift and Kubernetes environments.
For Kubernetes, you need to take some additional steps to install Voyager, the ingress controller we use.

## Configuration

The following table lists the configurable parameters of the edge chart and their default values.

### Global Configuration

| Parameter                        | Description       | Default    |
| -------------------------------- | ----------------- | ---------- |
| global.environment               |                   | openshift |
| global.domain                    | edge-ingress.yaml |            |
| global.route_url_name            | edge-ingress.yaml |            |
| global.remove_namespace_from_url | edge-ingress.yaml | false      |
| global.catalog.version           |                   | 0.3.6      |
| global.dashboard.version         |                   | latest     |
| global.data.version              |                   | 0.2.3      |
| global.documentation.version     |                   | 3.0.0      |
| global.edge.version              |                   | 0.7.1      |
| global.exhibitor.replicas        |                   | 1          |
| global.exhibitor.version         |                   |            |
| global.jwt.version               |                   | 0.2.0      |
| global.slo.version               |                   | 0.4.0      |
| global.xds.cluster               |                   | greymatter |
| global.xds.port                  |                   | 18000      |
| global.xds.version               |                   | 0.2.6      |

### Sidecar Configuration

Grey Matter supports defining default values for sidecar environment variables to help quickly change properties of the service mesh instantly across every component. These are set in the `global.sidecar` key. However, we also support overwriting default sidecar environment variables at the subchart/service level for flexibility and customization.

In the table below we outline all of the supported sidecar environment variables along with their default global values. For this documentation, we will simply use the key used to configure that variable, which is accessible and configurable at both `global.sidecar.envvars.<key>` or `sidecar.envvars.<key>`.

| Environment Variable    | Description                       | Default |
| ----------------------- | --------------------------------- | ------- |
| ingress_use_tls         | true                              |         |
| ingress_ca_cert_path    | /etc/proxy/tls/sidecar/ca.crt     |         |
| ingress_cert_path       | /etc/proxy/tls/sidecar/server.crt |         |
| ingress_key_path        | /etc/proxy/tls/sidecar/server.key |         |
| metrics_key_function    | depth                             |         |
| metrics_port            | 8081                              |         |
| proxy_dynamic           | true                              |         |
| service_host            | 127.0.0.1                         |         |
| obs_enabled             | false                             |         |
| obs_enforce             | false                             |         |
| obs_full_response       | false                             |         |
| kafka_enabled           | false                             |         |
| kafka_zk_discover       | false                             |         |
| kafka_server_connection | kafka:9091,kafka2:9091            |         |
| port                    |                                   |         |
| service_port            |                                   |         |
| kafka_topic             |                                   |         |
| zk_addrs                |                                   |         |
| zk_announce_path        |                                   |         |
| egress_use_tls          |                                   |         |
| egress_ca_cert_path     |                                   |         |
| egress_cert_path        |                                   |         |
| egress_key_path         |                                   |         |

#### Caveats
This is implemented by a helper template (in  `templates/_helpers.tpl`) which loops over the global envvars and uses local ones if they are available. This means that to use a sidecar environment variable at the local level, its name and type must already be defined at the global level, however, a global default does not need to be set.

If no value is found, either at the local level or in a global default, the template will just ignore that environment variable.

To support deploying the services individually, we copy the `greymatter` `_envvars_.tpl` into each service's `template` folder, which allows Helm to see it even when it is note used as a subchart. The template determines that if the value `.Values.global.sidecar` is not set, then it will only use the local `.Values.sidecar` options.
To copy `_envvars.tpl`, run this command:

```sh
echo **/templates | xargs -n 1 | grep -v greymatter/ | xargs -I{} sh -c 'cp greymatter/templates/_envvars.tpl "$1"' -- {}
```

## Testing the Chart

To run a test, wait for dashboard to startup and you can hit the url displayed in the release notes, then use:

```console
$ helm test <deployment_name>
```

ex:

```console
$ helm test greymatter_test_deploy

#Result

RUNNING: greymatter_test_deploy-connection-test
PASSED: greymatter_test_deploy-connection-test
```

Running this command will spin up a new pod named `<service>-<deployment_name>-connection-test` which will run the tests defined in `greymatter/templates/tests`. These test pods do not automatically delete so if they need to be run multiple times then they will need to be deleted manually in the ui or with `oc delete pod <name>`.

### Tests

| Test Name               | Description            | Desired Result |
| ----------------------- | ---------------------- | -------------- |
| documentation-test.yaml | curl documentation url | 200            |
| catalog-test.yaml       | curl catalog url       | 200            |

## Uninstalling the Chart

To uninstall/delete the `<my-release>` deployment:

```console
$ helm delete <my-release>
```

The command removes all components associated with the chart and deletes the release.

## Configuration

The following table lists the configurable parameters of the greymatter chart and their default values.

| Parameter                     | Description  | Default                               |
| ----------------------------- | ------------ | ------------------------------------- |
|                               |              |                                       |
| sidecar.create_sidecar_secret | Create Certs | false                                 |
| sidecar.certificates          |              | {name:{ca: ... , cert: ..., key ...}} |

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

- All the files listed under this variable will overwrite any existing files by the same name in the greymatter config directory.
- Files not mentioned under this variable will remain unaffected.

```console
$ helm install greymatter --name <my-release> \
  --set=jwt.version=v0.2.0, sidecar.ingress_use_tls='false'
```

Alternatively, a YAML file that specifies the values for the above parameters can be provided while installing the chart. For example :

```console
$ helm install greymatter --name <my-release> -f custom.yaml
```
