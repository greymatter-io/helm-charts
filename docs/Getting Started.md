# Getting Started

- [Getting Started](#getting-started)
  - [Helm](#helm)
  - [OpenShift](#openshift)
  - [Configuration](#configuration)
    - [Ingress](#ingress)
    - [Docker credentials](#docker-credentials)
    - [AWS credentials (optional)](#aws-credentials-optional)
    - [Certificates](#certificates)
    - [SPIRE](#spire)
    - [TLS Options](#tls-options)
    - [Single-service deployments](#single-service-deployments)
  - [Install](#install)
    - [Prepare Tiller](#prepare-tiller)
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

Our Helm charts can be overridden by custom YAML files that are chained together during install. We've provided two examples:

- [greymatter.yaml](../greymatter.yaml) provides a primary set of overrides
- [greymatter-secrets.yaml](../greymatter-secrets.yaml) provides a separate set of overrides specifically for passwords, secrets, and other sensitive data

Copy these files to `custom-greymatter.yaml` and `custom-greymatter-secrets.yaml` as we'll be making changes to them. They will not be picked up by Git.

At the top of `custom-greymatter.yaml`, set the following four values according to your needs.

```yaml
global:
  # used in our subcharts to apply platform specific settings, values can be `openshift` or `kubernetes` only
  environment: openshift

  # the domain you're deploying to
  domain: development.deciphernow.com

  # a string that will be prefixed to the final hostname of the deployment
  route_url_name: greymatter

  # whether to include the virtual cluster namespace in the final hostname of the deployment
  remove_namespace_from_url: false
```

### Ingress

If you're using OpenShift, you can skip to the next section because OpenShift will create a route using the `domain` value. For Kubernetes, we recommend the [Voyager Ingress Controller](https://appscode.com/products/voyager/), which automatically provisions a load balancer from a variety of supported cloud providers like EKS in AWS. This allows you to access the cluster at the provided load balancer URL. Add the following Voyager configuration to your `custom-greymatter.yaml` file. Ensure that the value for `cloudProvider` is one of the [supported providers](https://appscode.com/products/voyager/7.1.1/setup/install/#using-script).

```yaml
voyager:
  cloudProvider: aws
  enableAnalytics: false
```

At present, there's [an issue](https://github.com/appscode/voyager/issues/1415) specifying Voyager as a dependency, so we need to manually configure Voyager ingress as a prerequisite. This can be done with following commands:

```sh
# PROVIDER should match `cloudProvider` value
export PROVIDER=aws
helm repo add appscode https://charts.appscode.com/stable/
helm repo update
helm install appscode/voyager --name voyager-operator --version 10.0.0 \
  --namespace kube-system \
  --set cloudProvider=$PROVIDER \
  --set enableAnalytics=false \
  --set apiserver.enableAdmissionWebhook=false
```

Once the edge proxy is deployed, voyager-operator will create a custom ingress resource which will provision a load balancer for you. You can run `kubectl get svc voyager-edge` to see the cluster IP and port.

Read [Ingress](./Ingress.md) for further details.

### Docker credentials

At the top of your `custom-greymatter-secrets.yaml` file set your Docker credentials so Helm can pull the necessary Grey Matter images. If you need credentials please contact [Grey Matter Support](https://support.deciphernow.com).

```yaml
dockerCredentials:
  registry: docker.production.deciphernow.com
  email:
  username:
  password:
```

### AWS credentials (optional)

Set AWS credentials for gm-data to authenticate and push content to S3. This step is **optional** because gm-data stores files on disk or in S3. If you need credentials please contact [Grey Matter Support](https://support.deciphernow.com).

```yaml
data:
  data:
    aws:
      access_key:
      secret_key:
      region: us-east-1
      bucket: decipher-quickstart-helm
```

### Certificates

You may notice a large section of your `custom-greymatter-secrets.yaml` file containing TLS certificates with public and private keys. These are used in various services like gm-jwt-security, the Grey Matter sidecar, and edge proxy.

To access anything in the mesh, your request will pass through the edge proxy, which performs Mutual TLS (mTLS) authentication. Both the client and server must authenticate themselves and your browser (or other HTTPS client like `curl` or `wget`) will need to have the appropriate certificates loaded.

To keep things simple, `greymatter-secrets.yaml` uses the same certificates as those from `common/certificates/user/quickstart.p12` in the [DecipherNow/grey-matter-quickstart](https://github.com/DecipherNow/grey-matter-quickstarts) repository. If you load `quickstart.p12` into your browser, when you access the Grey Matter Dashboard, you'll be prompted to use that certificate to verify yourself.

For production deployments it's recommened to use certificates generated from a secure Certificate Auhority (CA).

### SPIRE

We also support using SPIFFE/SPIRE as a way to enable zero-trust attestation of different "workloads" (services).

Read [SPIRE](./SPIRE.md) for further details.

### TLS Options

We support multiple TLS options both for ingress/egress (north/south traffic) to the edge proxy, and between the sidecar proxies (east/west traffic) within the mesh. For ingress, we support mTLS or non-TLS. To do this, enable the following:

```yaml
edge:
  enableTLS: true
  certPath: /etc/proxy/tls/edge
```

Certs are volume mounted to the edge proxy Docker container at the location specified by `certPath`.

For securing communication between the sidecar proxies in the mesh, we support:

- Non-TLS
- Static mTLS (two-way TLS)
- SPIFFE/SPIRE mTLS with certificate rotation

If you want to disable TLS in the mesh, don't enable either of the following options.

For both of the following options, you need:

```yaml
mesh_tls:
  enabled: true
```

**Static mTLS** - this configures static mTLS between each proxy by mounting the appropriate certs and setting up the configuration in `gm-control-api`. Read [Control API](./Control%20API.md) for further details.

To enable it just set the following in your `custom-greymatter.yaml` file:

```yaml
mesh_tls:
  enabled: true
  use_provided_certs: true
```

Currently, this uses the certificates mounted at the path `/etc/proxy/tls/sidecar/`, but in the future this path may be configurable.

**SPIFFE/SPIRE mTLS** - enables the `spire` subchart, which creates the SPIRE agent and server. Also creates appropriate SPIRE registration entries automatically, and adds SPIRE secrets to the proxy and cluster configuration in `gm-control-api`

To enable it, set the following in your `custom-greymatter.yaml`:

```yaml
mesh_tls:
  enabled: true
spire:
  enabled: true
  trustDomain: deciphernow.com
```

### Single-service deployments

If you want to deploy a Helm chart for a single service without the entire service mesh, you need to make sure that your `custom-greymatter.yaml` `globals.sidecar.envvars` key contains all of the necessary global defaults for the sidecar. Otherwise, the sidecar will contain inappropriate environment variables for that deployment and will lead to your sidecar being mis-configured.

## Install

### Prepare Tiller

Tiller requires permissions to run installations in the cluster. Depending on your
setup and security requirements, these particular permissions will change. Please see
the [official Helm docs](https://helm.sh/docs/using_helm/#tiller-and-role-based-access-control) to prepare your
production setup, but we do provide highlights in our [Multi-tenant Helm guide](./Multi-tenant%20Helm.md).

For development deployments with Minikube, you can skip these steps and proceed on. Full Tiller access should be granted by default when installing with Minikube.

For a quick setup, giving Tiller full cluster-wide access, have an admin apply the `helm-service-account.yaml` found in this repository. This will enable Tiller
to act and install across the entire Kubernetes cluster.

For Openshift:
```
oc apply -f ./helm-service-account.yaml
```

For Kubernetes:
```
kubectl apply -f ./helm-service-account.yaml
```

You'll then be able to initialize Helm using this account:

```
helm init --service-account tiller
```

### Prepare Service Accounts

For production deployments, we recommend that an admin setup service accounts first following our [Service Accounts](./Service%20Accounts.md) guide because some of our services require cluster resources, such as read access to Kubernetes Pods. If Tiller has full cluster access then it will install the service accounts. This would be the default when installing in a simple fashion with Minikube.

### Latest Helm charts release

To install Helm charts representing the latest version of Grey Matter, you'll need to add the Grey Matter Helm repository to your local `helm` CLI. Run the following command, replacing username/password with credentials previously provided to you. These are the same as your Docker credentials.

```sh
helm repo add decipher https://nexus.production.deciphernow.com/repository/helm-hosted --username <username> --password '<password>'
helm repo update
```

Once the repository has successfully been added to your `helm` CLI, you can install Grey Matter from the latest charts.

**Note: Before installing Helm charts it's always prudent to do a dry-run first to ensure your custom YAML is correct. You can do this by adding the `--dry-run` flag to the below `helm install` command. If you receive no errors then you can confidently drop the `--dry-run` flag.**

```sh
helm install decipher/greymatter --namespace <project_namespace> --name <release_name> -f custom-greymatter.yaml -f custom-greymatter-secrets.yaml --tiller-namespace <tiller_namespace>
```

### Local Helm charts

If you've cloned this project and are changing charts locally, you'll need to modify the repository paths in `requirements.yaml` to point to the relative chart paths of this GitHub project.

```yaml
dependencies:
  - name: dashboard
    version: '2.0.1'
    repository: 'file://../dashboard'
```

Then you can run the following commands to update the local charts and then install them.

```sh
helm dep up greymatter
helm install greymatter --namespace <project_namespace> --name <release_name> -f custom-greymatter.yaml -f custom-greymatter-secrets.yaml --tiller-namespace <tiller_namespace>
```

The `helm dep up greymatter` command will create a `./greymatter/charts` directory with tarballs of each sub-chart that the parent `greymatter` chart will use to install Grey Matter.

### Additional Helm install flags

Here are some additional parameters we often use when running `helm install`:

- `-f` allows you to pass in a file with values that can override the chart's defaults (relative path)
- `--name` the release version of the project, service, etc.
- `--namespace` the namespace provided by the OpenShift/Kubernetes environment e.g. `fabric-development`
- `--tiller-namespace` the namespace of the Tiller pod in OpenShift/Kubernetes
- `--debug` prints out the deployment YAML to the terminal
- `--dry-run` w/ debug will print out the deployment YAML without actually deploying to OpenShift/Kubernetes environment
- `--replace` will create new deployments if they are undefined or replace old ones if they exist

## Verification

Once all pods, containers, and services start successfully you can confirm that the Grey Matter service mesh is running by navigating to its dashboard. You'll need to construct the URL from your global values in `custom-greymatter.yaml`.

For example, with the following configuration:

```yaml
global:
  environment: openshift
  domain: development.deciphernow.com
  route_url_name: greymatter
  remove_namespace_from_url: false
```

The URL will be `greymatter.{{ Release.Namespace }}.development.deciphernow.com`, so if you deployed into a OpenShift or Kubernetes namespace with a command like, `helm install decipher/greymatter --namespace mesh`, the final URL would be: `https://greymatter.mesh.development.deciphernow.com`. That URL will route you to the Grey Matter dashboard and you can confirm that the core services are up and running.
