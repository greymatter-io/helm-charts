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

All configuration options and their default values are listed in [configuration.md](configuration.md).

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

## Configuration with RDS Postgres

You can optionally configure the SLO service to run with an Amazon RDS instance of Postgres. This involves setting `{{ .Values.postgres.rds.enabled }}` to `true` and `{{ .Values.postgres.rds.endpoint }}` to your database endpoint. Since we're using one-way SSL, you only need to set the ca.pem to the appropriate AWS rds root certificate which can be found [here](https://s3.amazonaws.com/rds-downloads/rds-ca-2015-root.pem). This value goes into `{{ .Values.postgres.ssl.certificates.ca }}`. Your RDS should be publicly accessible, with a new DB parameter group and parameter named `rds.force_ssl` with value `1`.  Make sure the security group you're using allows for ingress traffic from your IP.
