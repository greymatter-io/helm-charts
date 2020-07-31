# Getting Started

- [Getting Started](#getting-started)
  - [Helm](#helm)
  - [OpenShift](#openshift)
  - [Configuration](#configuration)
    - [Storage](#storage)
    - [Ingress](#ingress)
    - [Observables](#observables)
    - [Docker credentials](#docker-credentials)
    - [AWS credentials (optional)](#aws-credentials-optional)
    - [Certificates](#certificates)
    - [SPIRE](#spire)
    - [TLS Options](#tls-options)
    - [Single-service deployments](#single-service-deployments)
  - [Install](#install)
    - [Prepare Service Accounts](#prepare-service-accounts)
    - [Latest Helm charts release](#latest-helm-charts-release)
    - [Local Helm charts](#local-helm-charts)
    - [Additional Helm install flags](#additional-helm-install-flags)
  - [Verification](#verification)

This guide assumes that your target environment is a hosted Kubernetes based platform. If you want to test drive Grey Matter on your local machine, follow [Deploy with Minikube](./Deploy%20with%20Minikube.md).

## Helm

Follow the [Helm install docs](https://helm.sh/docs/using_helm/#quickstart) to install Helm locally. Once completed you should have the following tools installed:

- `helm`
- `kubectl`

## OpenShift

If you're deploying to OpenShift you need to [install the oc cli](https://docs.openshift.com/enterprise/3.0/cli_reference/get_started_cli.html#installing-the-cli) and login to your OpenShift environment.

```sh
# Example
oc login development.deciphernow.com
```

## Configuration

Our Helm charts can be overridden by custom YAML files that are chained together during install.  Follow the structure of the `<chart>/values.yaml` file for the chart you are installing to create a `custom.yaml` with overrides.


### Storage

The Grey Matter Helm chart assumes that your Kubernetes cluster has a default storage provider already defined.  The charts will attempt to create several PersistentVolumeClaims for data storage, and if a default storage provider has not been declared, the installation will fail.  Additionally, the Mongo StatefulSets declare a Persistent Volume Template that requires that a Storage Class be defined.  If there is no default StorageClass in your cluster, you must provide a StorageClass name for the Mongo chart.  This variable can be set for the [Data chart](./../data/Chart.yaml) at `.Values.data.mongo.storage.storageClass` and `.Values.internal-data.mongo.storage.storageName`

### Ingress

If you're using OpenShift, you can skip to the next section because OpenShift will create a route using the `global.domain` value set in the [Edge chart](./../edge/Chart.yaml). 

By default, we use an nginx ingress configuration. This ingress will be set up automatically.

If you prefer to use a [Voyager Ingress Controller](https://appscode.com/products/voyager/) for ingress, before intalling the charts,

```bash
cd voyager
make voyager
```

and set `edge.ingress.use_voyager` to true in `edge/values.yaml`.

This will generate an ingress with voyager that looks like the following:

```yaml
edge:
  ingress:
    apiVersion: voyager.appscode.com/v1beta1
    annotations:
      kubernetes.io/ingress.class: 'voyager'
      ingress.appscode.com/ssl-passthrough: 'true'
      ingress.appscode.com/type: NodePort
    rules:
      - tcp:
          port: '80'
          nodePort: '30001'
          backend:
            serviceName: edge
            servicePort: 10808
      - tcp:
          port: '443'
          nodePort: '30000'
          backend:
            serviceName: edge
            servicePort: 10808
```

Once the edge proxy is deployed, voyager-operator will create a custom ingress resource which will provision a load balancer for you. You can run `kubectl get svc voyager-edge` to see the cluster IP and port.

Read [Ingress](./Ingress.md) for further details.

### Observables

The Grey Matter Helm chart provides the ability to enable observables in the mesh, but they are disabled by default.  To enable observables, modify the following settings in your local custom values file.  The `kafkaServerConnection` should be a reference to a Kafka ensemble that is available in the mesh.  The format is `<host1>:<port1>,<host2>:<port2>`

These are global settings for all observables:

```yaml
globals:
  observables:
    topic: observables
    kafkaServerConnection:
```

Observables can be enabled or disabled for each service.  You can enable observables by setting `.Values.global.services.<service>.observablesEnabled` to `true` or `false`

### Docker credentials

Before installing the secrets chart, or your own series of secrets, a docker secret with docker credentials to pull the Grey Matter images must be created. By default, it is named `docker.secret`, but a secret with a different name can be used as long as `.Values.global.image_pull_secret` is set to the name of the secret in all of the Grey Matter charts.

Run `make credentials` to generate a `credentials.yaml` file.  It will prompt you for your registry and credentials and (optionally) your [AWS credentials](#aws-credentials-optional).  The `credentials.yaml` file will look like the following:

```yaml
dockerCredentials:
  - registry: docker.production.deciphernow.com
    email:
    username:
    password:

data:
  aws:
    access_key:
    secret_key:
    region: us-east-1
    bucket: decipher-quickstart-helm
```

To add another docker registry with credentials to the secrets, simply add another block to the `dockerCredentials` list:

```yaml
  - registry: second.docker.registry
    email:
    username:
    password:
```

To install, run `make secrets`. The `docker.secret` will have creall registries in this file.  If you need credentials please contact [Grey Matter Support](https://support.deciphernow.com).

### AWS credentials (optional)

Set AWS credentials for gm-data to authenticate and push content to S3. This step is **optional** because gm-data stores files on disk or in S3. If you need credentials please contact [Grey Matter Support](https://support.greymatter.io).

```yaml
data:
  aws:
    access_key:
    secret_key:
    region: us-east-1
    bucket: decipher-quickstart-helm
```

### Certificates

The Grey Matter [Secrets chart](../secrets/Chart.yaml) contains the default values for all Grey Matter certificates and credentials.  Deploying this chart will generate all of the necessary secrets to run Grey Matter.

To access anything in the mesh, your request will pass through the edge proxy, which performs Mutual TLS (mTLS) authentication. Both the client and server must authenticate themselves and your browser (or other HTTPS client like `curl` or `wget`) will need to have the appropriate certificates loaded.

If you load `quickstart.p12` into your browser, when you access the Grey Matter Dashboard, you'll be prompted to use that certificate to verify yourself.

For production deployments it's recommened to use certificates generated from a secure Certificate Authority (CA).  Kubernetes secrets must be created containing any necessary certificates. Then, to use them in Grey Matter, set `.Values.<service>.secret` to the with information pointing to the secret for whichever `<service>`
the certificates are to be set on.

For example, if you generate a secret with certificates that you wish to use for gm-data called `data-override-secret`, in `.Values.data` you should have something like the following:

```yaml
data:
  data:
    secret:
      secret_name: data-override-secret
      mount_point: /certs/
      secret_keys:
        ca: <key in secret for ca>
        cert: <key in secret for cert>
        key: <key in secret for key>
```

There is a global certs option that allows you to use a single set of certificates mounted for all services in the mesh.  To configure this, in your `global.yaml` file set:

```yaml
global:
  global_certs:
    enabled: false
    certificates:
      from_file:
        enabled: false
        path: files/certs/global
      ca:
      cert:
      key:
```

The certificates themselves can either be added here in the `certificates.ca`, `certificates.key`, and `certificates.cert` values.  They can also be pulled from file, to do this, set `from_file.enabled` to true and indicate where the secrets chart can find the desired files.

With the global option, you can also configure a separate certificate for edge ingress. To do this, if `global.global_certs.enabled` is true, set `edge.certificates.ingress.unique` to true and indicate where to pull that cert from in the same way.  Otherwise, edge ingress will use the same global certificates as the other services.

From file certificates can also be specified for particular services, this can be done by setting the `<service>.secret.certificates.from_file.enabled` to true and setting the location in the same way.

See the [secrets chart documentation](../secrets/README.md) for more information.

### SPIRE

We also support using SPIFFE/SPIRE as a way to enable zero-trust attestation of different "workloads" (services).

Read the [spire docs](./spire/configuration.md) for further details.

### TLS Options

We support multiple TLS options both for ingress/egress (north/south traffic) to the edge proxy, and between the sidecar proxies (east/west traffic) within the mesh. For ingress, we support mTLS or non-TLS. To do this, enable the following:

```yaml
edge:
  # If set, enables egress TLS from the edge proxy using the secret specified in secret_name
  egress:
    secret:
      secret_name: greymatter-edge-egress
      mount_point: /etc/proxy/tls/sidecar/
  # If set, enables ingress TLS on the edge proxy using the secret specified in secret_name
  ingress:
    secret:
      secret_name: greymatter-edge-ingress
      mount_point: /etc/proxy/tls/edge/
```

Certs are volume mounted to the edge proxy Docker container at the location specified by `mount_point`.

For securing communication between the sidecar proxies in the mesh, we support:

- Non-TLS
- Static mTLS (two-way TLS)
- SPIFFE/SPIRE mTLS with certificate rotation

If you want to disable TLS in the mesh, don't set `.Values.<service>.secret` on the Grey Matter services.

**Static mTLS** - this configures static mTLS between each proxy by mounting the appropriate certs on the sidecar container.  Set `.Values.<service>.sidecar.secret` to point at the correct secret to configure this.

For example, the default secret set on each sidecar is `sidecar-certs`, mounted at `/etc/proxy/tls/sidecar`:

```yaml
  secret:
    secret_name: sidecar-certs
    mount_point: /etc/proxy/tls/sidecar/
    secret_keys:
      ca: ca.crt
      key: server.key
      cert: server.crt
```

**SPIFFE/SPIRE mTLS** - enables the `spire` subchart, which creates the SPIRE agent and server. Also creates appropriate SPIRE registration entries automatically, and adds SPIRE secrets to the proxy and cluster configuration in `control-api`

To enable it, set the following in your `<chart>/values.yaml` or `custom.yaml`:

```yaml
global:
  spire:
    enabled: true
    trustDomain: quickstart.greymatter.io
```

### Single-service deployments

If you want to deploy a Helm chart for a single service without the entire service mesh, you need to make sure that your `custom.yaml` `globals.sidecar.envvars` key contains all of the necessary global defaults for the sidecar. Otherwise, the sidecar will contain inappropriate environment variables for that deployment and will lead to your sidecar being mis-configured.

## Install

### Prepare Service Accounts

For production deployments, we recommend that an admin setup service accounts first following our [Service Accounts](./Service%20Accounts.md) guide because some of our services require cluster resources, such as read access to Kubernetes Pods.

### Latest Helm charts release

To install Helm charts representing the latest version of Grey Matter, you'll need to add the Grey Matter Helm repository to your local `helm` CLI. Run the following command, replacing username/password with credentials previously provided to you. These are the same as your Docker credentials.

```sh
helm repo add greymatter https://nexus.greymatter.io/repository/helm-release --username <username> --password '<password>'
helm repo update
helm search repo
```

Once the repository has successfully been added to your `helm` CLI, you can install Grey Matter from the latest charts.

**Note: Before installing Helm charts it's always prudent to do a dry-run first to ensure your custom YAML is correct. You can do this by adding the `--dry-run` flag to the below `helm install` command. If you receive no errors then you can confidently drop the `--dry-run` flag.**

### Local Helm charts

If you are modifying charts or want to run development versions of charts you'll need to clone this repository.

```sh
git clone git@github.com:DecipherNow/helm-charts.git
```

Then you can run the following commands to update the local charts and then install them.

```sh
helm dep up <chart>
helm install <release-name> <chart> --namespace <project_namespace> --name <release_name> -f <optional config overrides>
```

The `helm dep up <chart>` command will create a `./<chart>/charts` directory with tarballs of each sub-chart that the parent chart will use to install Grey Matter.

### Additional Helm install flags

Here are some additional parameters we often use when running `helm install`:

- `-f` allows you to pass in a file with values that can override the chart's defaults (relative path)
- `--namespace` the namespace provided by the OpenShift/Kubernetes environment e.g. `fabric-development`
- `--debug` prints out the deployment YAML to the terminal
- `--dry-run` w/ debug will print out the deployment YAML without actually deploying to OpenShift/Kubernetes environment

## Verification

We can run `helm ls` to see all our current deployments and `helm uninstall <release name>` to delete deployments. If you need to make changes, you can run `helm upgrade <release name> <chart> -f <optional config overrides>` to update your release in place.

You should also load the appropriate user p12 file according to the certs you configured when deploying Greymatter. The default certs correspond to the quickstart certificates and the `quickstart.p12` file can be found at `certs/quickstart.p12`. You will want to follow your browser specific instructions to load in this user pki. 
[Firefox](https://www.sslsupportdesk.com/how-to-import-a-certificate-into-firefox/) and [Chrome](https://support.globalsign.com/customer/en/portal/articles/1211541-install-client-digital-certificate---windows-using-chrome) instructions.

You can confirm that the Grey Matter service mesh is running by navigating to its dashboard. You'll need to construct the URL from your global values in `edge/values.yaml`.

For example, with the following configuration:

```yaml
global:
  environment: openshift
  domain: development.deciphernow.com
  route_url_name: greymatter
  remove_namespace_from_url: 'false'
```

The URL will be `greymatter.{{ Release.Namespace }}.development.deciphernow.com`, so if you deployed into a OpenShift namespace, the final URL would be: `https://greymatter.mesh.development.deciphernow.com`. That URL will route you to the Grey Matter dashboard and you can confirm that the core services are up and running.
