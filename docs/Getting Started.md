
# Getting Started

This guide describes how to deploy Grey Matter to an Openshift or Kubernetes environment using Helm.

- [Getting Started](#getting-started)
  - [1. Prerequisites](#1-prerequisites)
    - [Helm](#helm)
    - [Kubernetes cluster](#kubernetes-cluster)
      - [OpenShift](#openshift)
  - [2. Helm Values Configuration](#2-helm-values-configuration)
    - [Basic values](#basic-values)
    - [Ingress into the cluster](#ingress-into-the-cluster)
    - [Docker credentials](#docker-credentials)
    - [AWS credentials (optional)](#aws-credentials-optional)
    - [Certificates](#certificates)
    - [TLS Options](#tls-options)
    - [Single-service deployments](#single-service-deployments)
  - [3. Environment specific configuration](#3-environment-specific-configuration)
  - [4. Install Grey Matter](#4-install-grey-matter)
    - [Install via hosted Helm charts](#install-via-hosted-helm-charts)
    - [Install via local Helm charts](#install-via-local-helm-charts)
  - [5. Verify installation](#5-verify-installation)
  - [6. Additional information](#6-additional-information)

## 1. Prerequisites

### Helm

Follow the [Helm install docs](https://helm.sh/docs/using_helm/#quickstart) to install Helm on your local machine. Once completed you should have the following tools installed:

- `helm` (Helm CLI)
- `tiller` (component of Helm running within the Kubernetes cluster)
- `kubectl` (Kubernetes CLI)

### Kubernetes cluster

To deploy Grey Matter via Helm, a Kubernetes cluster must be setup. For local testing you may use [minikube](https://github.com/kubernetes/minikube) but for the remainder of this document, we'll assume you're deploying to a hosted "bare" Kubernetes or Openshift cluster. Other Kubernetes distributions will require additional configuration and will theoretically work but we have yet to test them.

#### OpenShift

If you're using an OpenShift environment, you need to:

- [Install the oc cli](https://docs.openshift.com/enterprise/3.0/cli_reference/get_started_cli.html#installing-the-cli)
- Login to the environment e.g. `development.deciphernow.com`

Run `oc login`, which will respond with:

```bash
Login failed (401 Unauthorized)
Verify you have provided correct credentials.
You must obtain an API token by visiting https://development.deciphernow.com:8443/oauth/token/request
```

Follow the link provided, click on "Display Token" and copy the command under "Log in with this token". Run the command, similar to the one below, to login to OpenShift.

```bash
oc login --token=<the_token> --server=https://development.deciphernow.com:8443
```

## 2. Helm Values Configuration

Each Helm chart has a `values.yaml` file which specifies the default values used to generate/template the final Kubernetes resource files with YAML. These values can be overwritten by you by chaining one or more files during install.

We've provided two examples:

- [greymatter-custom.yaml](../greymatter-custom.yaml): showcases the general structure of a Helm values file and shows how top-level values are passed down to subcharts
- [greymatter-custom-secrets.yaml](../greymatter-custom-secrets.yaml): a values file containing just passwords, secrets, and other sensitive data

### Basic values

Setup the basic information about your deployment by editing the following:

```yaml
global:
  environment: # openshift or kubernetes
  domain:
  route_url_name:
```

The final domain of your Grey Matter deployment will be located at `<route_url_name>.<helm_release_namespace>.<domain>`. This can be changed by setting `remove_namespace_from_url` to `true` which would remove the Helm release namespace from the URL.

For example, with the following configuration:

```yaml
global:
  environment: openshift
  domain: development.deciphernow.com
  route_url_name: greymatter
  remove_namespace_from_url: false
```

the URL would be `greymatter.{{ Release.Namespace }}.development.deciphernow.com`, so if you deployed into a Kubernetes namespace with a command like, `helm install decipher/greymatter --namespace mesh`, the final URL would be: `greymatter.mesh.development.deciphernow.com`.

### Ingress into the cluster

Depending on your environment, either OpenShift or a Kubernetes, you'll need to set up ingress into the cluster. For OpenShift, the only thing you need to do is set the proper `domain`, e.g. your OpenShift cluster URL, and the Helm charts will automatically create an OpenShift route as described above.

For Kubernetes, e.g. in a managed Kubernetes service (like EKS) from a cloud provider (like AWS), you need to set up the Voyager ingress controller, which automatically provisions a cloud load balancer from a variety of supported cloud providers. This allows you to access the cluster at the provided load balancer URL.

To use Voyager, you need to set the type of environment you are in and pass it to the Voyager edge proxy.
Edit `cloudProvider` in the following to be one of the [supported providers](https://appscode.com/products/voyager/7.1.1/setup/install/#using-script)

```yaml
voyager:
  cloudProvider: # aws | gce | gks | azure | aks | baremetal | some others
  enableAnalytics: false
```

More details on Voyager are in [`edge/README.md`](edge#setting-up-the-ingress).

### Docker credentials

Set your Docker credentials in the secrets file so Helm can pull the necessary Grey Matter images:

```yaml
dockerCredentials:
  registry: docker.production.deciphernow.com
  email: your Decipher email address
  username: your Decipher LDAP username
  password: your Decipher LDAP password
```

### AWS credentials (optional)

Set AWS credentials for gm-data to authenticate and push content to S3. This step is **optional** because gm-data stores files on the filestystem or S3. In production, an AWS service account would be used, but for development purposes you need to have the ability to create an S3 bucket or access to an existing bucket e.g. `decipher-quickstart-helm`. If you cannot do either, contact [an admin](mailto:admin@deciphernow.com) to request credentials.
  
```yaml
data:
  ...
  data:
    ...
    aws:
      access_key: access key value
      secret_key: secret key value
      region: us-east-1
      bucket: decipher-quickstart-helm
```

### Certificates

You may notice a huge section of the secrets file which is just various TLS certificates with public and private keys. These are used in many services, including JWT, the sidecar, and the edge.

To actually access the Grey Matter Dashboard or any other service in the cluster, your request will pass through the edge service, which performs mTLS or Mutual TLS. This means that both the client and the server must authenticate themselves, and that your browser (or other HTTPS client e.g. `curl`) will need to have the appropriate certificates loaded.

To keep things simple, the `example-custom.yaml` uses the same certificates as those from `common/certificates/user/quickstart.p12` in the [DecipherNow/grey-matter-quickstart](https://github.com/DecipherNow/grey-matter-quickstarts) repository.

If you load `quickstart.p12` into your browser, when you access the Grey Matter Dashboard, you'll be prompted to use that certificate to verify yourself, which you should do to gain access.

We also support using SPIFFE/SPIRE as a way to enable zero-trust attestation of different "workloads" (services).

### TLS Options

We support multiple TLS options both for ingress to the edge proxy, and between the sidecar proxies in the mesh. For ingress, we support mTLS or no TLS. To do this, enable the following:

``` yaml
edge:
  enableTLS: true
  certPath: /etc/proxy/tls/edge
```

Most of our deployments enable ingress mTLS, so we haven't tested plain HTTP that much.

For securing communication between the sidecar proxies in the mesh, we support:

- No TLS
- Static mTLS (two-way TLS)
- SPIFFE/SPIRE mTLS with certificate rotation

Firstly, if you want to disable TLS in the mesh, just don't enable either of the following options.

For both of the following options, you need:

```yaml
mesh_tls:
  enabled: true
```

**Static mTLS** - this configures static mTLS between each proxy by mounting the appropriate certs and setting up the configuration in `gm-control-api`

To enable it just set the following in your `custom.yaml`:

```yaml
mesh_tls:
  enabled: true
  use_provided_certs: true
```

Currently, this just uses the certificates mounted at the path `/etc/proxy/tls/sidecar/`, but in the future this path may be configurable.

**SPIFFE/SPIRE mTLS** - enables the `spire` subchart, which creates the SPIRE agent and server. Also creates appropriate SPIRE registration entries automatically, and adds SPIRE secrets to the proxy and cluster configuration in `gm-control-api`

To enable it just set the following in your `custom.yaml`:

```yaml
mesh_tls:
  enabled: true
spire:
  enabled: true
  trustDomain: deciphernow.com
```

### Single-service deployments

If you want to deploy a Helm chart for a single service without the entire service mesh, you need to make sure that your `custom.yaml` `globals.sidecar.envvars` key contains all of the necessary global defaults for the sidecar environment variables. You can just copy these values from our `example-custom.yaml` file. Otherwise, the sidecar for the single service will only contain the environment variables that are different for that service. This will most likely break your sidecar installation, so be sure that you set these values.

## 3. Environment specific configuration

At the time of this writing, there is [an issue](https://github.com/appscode/voyager/issues/1415) specifying Voyager as a dependency, so we need to manually configure Voyager ingress before launching our Grey Matter cluster. This can be done with following commands:

```bash
export PROVIDER=minikube
helm repo add appscode https://charts.appscode.com/stable/
helm repo update
helm install appscode/voyager --name voyager-operator --version 10.0.0 \
  --namespace kube-system \
  --set cloudProvider=$PROVIDER \
  --set enableAnalytics=false \
  --set apiserver.enableAdmissionWebhook=false
```

Now you're all set. When you deploy the edge service, voyager-operator will create a custom `Ingress` resource which will provision a load balancer for you. You can run `kubectl get svc voyager-edge` to see the cluster ip and port.

See `docs/Ingress.md` for more information.

## 4. Install Grey Matter

### Install via hosted Helm charts

To install Helm charts representing the latest version of Grey Matter, you'll need to add Decipher's hosted Helm repository to your local `helm` CLI. Run the following command, replacing username/password with your Decipher LDAP credentials.

```bash
helm repo add decipher https://nexus.production.deciphernow.com/repository/helm-hosted --username <ldap username> --password '<ldap password>'
```

Using the example custom values files from section 2, you will be able to deploy Grey Matter to an OpenShift environment from the hosted repository with these commands.

```bash
helm repo update
helm install decipher/greymatter --name <release_name> --namespace <my_namespace> -f greymatter-custom.yaml -f greymatter-custom-secrets.yaml greymatter --tiller-namespace <tiller_namespace>
```

See section 5 for a detailed description on the parameters used above.

### Install via local Helm charts

If you've cloned this project and are developing charts locally, you'll need to change the source of each chart in `requirements.yaml` to use local paths.

```yaml
dependencies:
  - name: dashboard
    version: '1.0.0'
    repository: 'file://../dashboard'
```

Then you can run the following commands to update the local charts and then install them.

```bash
helm dep up greymatter
helm install greymatter --name <release_name> --namespace <my_namespace> -f greymatter-custom.yaml -f greymatter-custom-secrets.yaml greymatter --tiller-namespace <tiller_namespace>
```

These commands will create a `charts/` directory with tarballs of the child charts that the parent `greymatter` chart will use to install Grey Matter.

## 5. Verify installation

Once all pods, containers, and services start successfully you can confirm that the Grey Matter service mesh is running by navigating to its dashboard. As stated in section 2, you'll need to construct the URL from your global values in your custom values file(s), plus the release namespace you provided to OpenShift or Kubernetes.

For example, with the following configuration:

```yaml
global:
  environment: openshift
  domain: development.deciphernow.com
  route_url_name: greymatter
  remove_namespace_from_url: false
```

The URL will be `greymatter.{{ Release.Namespace }}.development.deciphernow.com`, so if you deployed into a OpenShift or Kubernetes namespace with a command like, `helm install decipher/greymatter --namespace mesh`, the final URL would be: `https://greymatter.mesh.development.deciphernow.com`. That URL will route you to the Grey Matter dashboard and you can confirm that the core services are up and running.

## 6. Additional information

Here are some additional parameters we often use when running `helm install`:

- `-f` allows you to pass in a file with values that can override the chart's defaults (relative path)
- `--name` the release version of the project, service, etc.
- `--namespace` the namespace provided by the Openshift/Kubernetes environment e.g. `fabric-development`
- `--tiller-namespace` the namespace of the Tiller pod in Openshift/Kubernetes
- `--debug` prints out the deployment YAML to the terminal
- `--dry-run` w/ debug will print out the deployment YAML without actually deploying to OpenShift/Kubernetes environment
- `--replace` will create new deployments if they are undefined or replace old ones if they exist

To install the entire Grey Matter service mesh, it's always prudent to do a dry-run first to ensure that your charts are configured correctly.

```bash
helm install decipher/greymatter -f custom.yaml --name gm-deploy --namespace fabric-development --tiller-namespace helm --debug --dry-run
```

If the result of running the above command prints YAML to your terminal then your charts are configured correctly. Once you're ready, drop the `--dry-run` parameter and run the command again. At this point, `helm` has successfully instructed `tiller` to deploy Grey Matter to the Openshift/Kubernetes environment.
