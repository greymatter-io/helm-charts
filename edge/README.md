# Edge

## TL;DR

```sh
helm install edge
```

## Introduction

This chart bootstraps an edge deployment on a [Kubernetes](http://kubernetes.io) or [OpenShift](https://www.openshift.com/) cluster via [Helm](https://helm.sh).

## Installing the Chart

To install the chart with the release name `<my-release>`, run the following command:

```sh
helm install edge --name <my-release>
```

The command deploys edge on the cluster in the default configuration. The [configuration](#configuration) section lists the parameters that can be configured during installation.

## Uninstalling the Chart

To delete the `<my-release>` deployment, run the following command:

```sh
helm delete <my-release>
```

The command removes all components associated with the chart and deletes the release.

## Configuration

All configuration options and their default values are listed in [configuration.md](configuration.md).

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example:

- All the files listed under this variable will overwrite any existing files by the same name in the edge config directory.
- Files not mentioned under this variable will remain unaffected.

```sh
helm install edge --name <my-release> \
--set=jwt.version=v0.2.0
```

Alternatively, a YAML file that specifies the values for the above parameters can be provided while installing the chart. For example:

```sh
helm install edge --name <my-release> -f custom.yaml
```
