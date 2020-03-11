# GM-data

## TL;DR;

```console
$ helm install gm-data
```

## Introduction

This chart bootstraps a data deployment on a [Kubernetes](http://kubernetes.io) or [OpenShift](https://www.openshift.com/) cluster using the [Helm](https://helm.sh) package manager.

## Installing the Chart

To install the chart with the release name `<my-release>`:

```console
$ helm install gm-data --name <my-release>
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
$ helm install gm-data --name <my-release> \
  --set=jwt.version=v0.2.0, sidecar.ingress_use_tls='false'
```

Alternatively, a YAML file that specifies the values for the above parameters can be provided while installing the chart. For example :

```console
$ helm install gm-data --name <my-release> -f custom.yaml
```


## Data Standalone

To deploy data as a standalone service in its own namespace, change the `.Values.data.name` to `data-standalone` (it is important that this name matches the proxy name in the json configuration).  Set `.Values.data.deploy.standalone` to `true` to make sure all the secrets get created.  Also make sure that the image names and other provided configs are the ones you wish to use.

If Data is being deployed into its own namespace of a namespace separate from the rest of Grey Matter then the [Waiter Service Account](#Waiter-Service-Account) must be added.

You can install the chart as described above, making sure the tiller namespace is set to the namespace set aside to only contain data.

`helm install gm-data --name data-only --tiller-namespace=data-only`

To configure this standalone data into the mesh, follow the [Grey Matter Configuration Builder](#Grey-Matter-Configuration-Builder) section.

### Waiter Service Account

The standalone deployment relies on the `waiter` pod to ensure mongo is up, this requires the use of the waiter service account.  If your tiller service account has the ability to add roles then you can set `waiterSA: true`.  You may add the waiter service account manually by changing the namespace of the following snippet then using `kube apply -f` to apply the configurations.

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: waiter-sa
  namespace: NAMESPACE

---
# Grey Matter Waiter Role
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: waiter-sa-role
  namespace: NAMESPACE
rules:
  - apiGroups: ['']
    resources: ['endpoints']
    verbs: ['get', 'list', 'watch']
---
# Grey Matter Waiter Cluster Role Binding

kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: waiter-sa-rolebinding
  namespace: NAMESPACE
subjects:
  - kind: ServiceAccount
    name: waiter-sa
    namespace: NAMESPACE
roleRef:
  kind: Role
  name: waiter-sa-role
  apiGroup: rbac.authorization.k8s.io
---
```

### Custom values.yaml for Standalone Deployment

This is a typical custom deployment file for a standalone deployment of data.  

```yaml
# set to false if namespace already has docker secret
createDockerSecret: false

data:
  name: data-standalone-service
  imagePullSecret: docker.secret
  replicas: 3
  deploy:
    standalone: true
    waiterSA: false
    # false if secrets are already in namespace
    secrets: false
  aws:
    access_key: ASDFASDFWE
    secret_key: asdfasdfa
    region: us-east-1
    bucket: decipher-quickstart-helm

sidecar:
  certs:
    secret_name: 'sidecar'
  envvars:
    xds_host:
      type: value
      # Connection to greymatter control pod
      value: 'control.default.svc.cluster.local'

mongo:
  name: mongo-data-service
  credentials:
    # This needs to be a unique name
    secret_name: mongo-credentials-gm2

```

### Grey Matter Configuration Builder

To make configuring greymatter simpler for a standalone deployment you can use the [builder.sh](standalone-json-builder/builder.sh).  To use this cd into `standalone-json-builder` and run `./builder.sh`.  

Note: This builder makes a some assumptions:

  1. The terminal has made a connection to Grey Matter Control and can run `greymatter` commands using these environment variables:

     1. GREYMATTER_API_HOST
     2. GREYMATTER_API_SSLCERT
     3. GREYMATTER_API_SSLKEY
  2. The ports data and it's sidecar use have not been changed.

To use the script:

  1. The script will ask for a cluster name, this will be the value used for `.Values.data.name`.
  2. Once the builder script has run you will have a folder called `builder-output-<cluster-name-entered>`.
  3. This directory will contain the Grey Matter configurations for your standalone Data deployment, generic catalog entry, and scripts for deploying and removing them.

Add Configurations to Mesh:

  1. Inside this directory are two scripts `populate.sh` and `remove.sh`.
  2. `./populate.sh` will add all the Grey Matter objects into the mesh in the appropriate order.
  3. `./remove.sh` will remove them. Pretty complicated naming strategy!

Add Catalog Entry:

  1. In the catalog directory there is an entry `catalog.json` and scripts `add-entry.sh` and `remove-entry.sh`.
  2. `catalog.json` may be edited with more specific information related to the data deployment (owners, etc...), DO NOT change the `"clusterName":` value as this is what ties the catalog entry to the Data instance installed.
  3. `./catalog/add-entry.sh` will add the entry to catalog.
  4. `./catalog/remove-entry.sh` will remove the entry from catalog.
