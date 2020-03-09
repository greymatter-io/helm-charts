# Catalog

## TL;DR;

```console
$ helm install catalog
```

## Introduction

This chart bootstraps a gm-catalog deployment on a [Kubernetes](http://kubernetes.io) or [OpenShift](https://www.openshift.com/) cluster using the [Helm](https://helm.sh) package manager.

## Installing the Chart

To install the chart with the release name `<my-release>`:

```console
$ helm install gm-catalog --name <my-release>
```

The command deploys gm-catalog on the cluster in the default configuration. The [configuration](#configuration) section lists the parameters that can be configured during installation.

## Uninstalling the Chart

To uninstall/delete the `<my-release>` deployment:

```console
$ helm delete <my-release>
```

The command removes all components associated with the chart and deletes the release.

## Configuration

All configuration options and their default values are listed in [configuration.md](configuration.md).

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

- All the files listed under this variable will overwrite any existing files by the same name in the gm-catalog config directory.
- Files not mentioned under this variable will remain unaffected.

```console
$ helm install gm-catalog --name <my-release> \
  --set=jwt.version=v0.2.0, sidecar.ingress_use_tls='false'
```

Alternatively, a YAML file that specifies the values for the above parameters can be provided while installing the chart. For example :

```console
$ helm install catalog --name <my-release> -f custom.yaml
```

### Adding services

The catalog deployment template will generate additional services if more are provided. These services are defined as a series of values:

```console
catalog:
    services:
        service_#:
            capability: ''
            documentation: '<documentation_path>'
            name: '<service_name>'
            owner: '<owner>'
            version: "{{ $.Values.a_service_name.version | trunc 3 }}"
            zookeeper_announcement_point: "/services/slo/{{ $.Values.a_service_name.version }}/metrics"

a_service_name:
    version: 1.2.3
```

- Note the service version is defined outside the service.
