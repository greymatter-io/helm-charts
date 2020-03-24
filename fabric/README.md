# Grey Matter

## TL;DR

```sh
helm install greymatter
```

## Introduction

This chart bootstraps a Grey Matter deployment on a [Kubernetes](http://kubernetes.io) or [OpenShift](https://www.openshift.com/) cluster using the [Helm](https://helm.sh) package manager.

## Installing the Chart

To install the chart with the release name `<my-release>`:

```sh
helm install greymatter --name <my-release>
```

The command deploys Grey Matter on the cluster in the default configuration. The [configuration](#configuration) section lists the parameters that can be configured during installation.

## Uninstalling the Chart

To uninstall/delete the `<my-release>` deployment:

```sh
helm delete <my-release>
```

The command removes all components associated with the chart and deletes the release.

## Configuration

All configuration options and their default values are listed in [configuration.md](configuration.md).

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

- All the files listed under this variable will overwrite any existing files by the same name in the greymatter config directory.
- Files not mentioned under this variable will remain unaffected.

```sh
helm install greymatter --name <my-release> \
  --set=jwt.version=v0.2.0, sidecar.ingress_use_tls='false'
```

Alternatively, a YAML file that specifies the values for the above parameters can be provided while installing the chart. For example:

```sh
helm install greymatter --name <my-release> -f custom.yaml
```

## Makefile

| command        | description                          | comments |
| -------------- | ------------------------------------ | -------- |
| control        | install standalone control           |          |
| api            | install standalone control-api       |          |
| package-fabric | package fabric                       |          |
| fabric         | package and install fabric component |          |
| remove-fabric  | uninstalls fabric component          |          |
