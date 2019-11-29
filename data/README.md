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

All configuration options and their default values are listed in [configuration.md](configuration.md).

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


## Data Standalone

To deploy data as a standalone service in its own namespace, change the `.Values.data.name` to `data-standalone` (it is important that this name matches the proxy name in the json configuration).  Set `.Values.data.deploy.standalone` to `true` to make sure all the secrets get created.  Also make sure that the image names and other provided configs are the ones you wish to use.

You can install the chart as described above, making sure the tiller namespace is set to the namespace set aside to only contain data.

`helm install data --name data-only --tiller-namespace=data-only`

To configure this standalone data into the mesh, go into the `json-data-only` folder and run `./populate` to apply the json configs.
