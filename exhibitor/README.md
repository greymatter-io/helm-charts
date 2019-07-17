# Exhibitor

## TL;DR;

```console
$ helm install exhibitor
```

## Introduction

This chart bootstraps an exhibitor deployment on a [Kubernetes](http://kubernetes.io) or [OpenShift](https://www.openshift.com/) cluster using the [Helm](https://helm.sh) package manager.

## Installing the Chart

To install the chart with the release name `<my-release>`:

```console
$ helm install exhibitor --name <my-release>
```

The command deploys exhibitor on the cluster in the default configuration. The [configuration](#configuration) section lists the parameters that can be configured during installation.

## Uninstalling the Chart

To uninstall/delete the `<my-release>` deployment:

```console
$ helm delete <my-release>
```

The command removes all components associated with the chart and deletes the release.

## Configuration

The following table lists the configurable parameters of the exhibitor chart and their default values.

### Global Configuration

| Parameter                        | Description | Default    |
| -------------------------------- | ----------- | ---------- |
| global.environment               |             | openshift |
| global.domain                    |             |            |
| global.route_url_name            |             |            |
| global.remove_namespace_from_url |             |            |
| global.exhibitor.replicas        |             | 1          |
| global.xds.port                  |             | 18000      |
| global.xds.cluster               |             | greymatter |

### Service Configuration

| Parameter                           | Description | Default                                                                                                                                                                                       |
| ----------------------------------- | ----------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| exhibitor.aws.access_key            |             |                                                                                                                                                                                               |
| exhibitor.aws.secret_key            |             |                                                                                                                                                                                               |
| exhibitor.aws.region                |             |                                                                                                                                                                                               |
| exhibitor.aws.bucket                |             |                                                                                                                                                                                               |
| exhibitor.image                     |             |                                                                                                                                                                                               |
| exhibitor.replicas                  |             | 1                                                                                                                                                                                             |
| exhibitor.imagePullPolicy           |             | Always                                                                                                                                                                                        |
| exhibitor.resources.limits.cpu      |             | 2                                                                                                                                                                                             |
| exhibitor.resources.limits.memory   |             | 4Gi                                                                                                                                                                                           |
| exhibitor.resources.requests.cpu    |             | 1                                                                                                                                                                                             |
| exhibitor.resources.requests.memory |             | 2Gi                                                                                                                                                                                           |
| exhibitor.command                   |             | ["/exhibitor-wrapper"]                                                                                                                                                                        |
| exhibitor.args                      |             | ["-c", "s3", "--s3region", "$(AWS_REGION)", "--s3credentials", "/etc/exhibitor/credentials", "--s3config", "$(AWS_BUCKET):$(EXHIBITOR_FOLDER)/greymatter", "--hostname", "$(POD_IP_ADDRESS)"] |
| exhibitor.extraEnvVars              |             | {AWS_BUCKET: "{{ $.Values.exhibitor.aws.bucket }}", AWS_REGION: "{{ $.Values.exhibitor.aws.region }}", EXHIBITOR_FOLDER: "sub-exhibitor"                                                      |

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

- All the files listed under this variable will overwrite any existing files by the same name in the exhibitor config directory.
- Files not mentioned under this variable will remain unaffected.

```console
$ helm install exhibitor --name <my-release> \
  --set=jwt.version=v0.2.0, sidecar.ingress_use_tls='false'
```

Alternatively, a YAML file that specifies the values for the above parameters can be provided while installing the chart. For example :

```console
$ helm install exhibitor --name <my-release> -f custom.yaml
```
