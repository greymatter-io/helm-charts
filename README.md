[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
![Lint and Test Charts](https://github.com/greymatter-io/helm-charts/workflows/Lint%20and%20Test%20Charts/badge.svg)
![Helm Tests](https://github.com/greymatter-io/helm-charts/workflows/Helm%20Tests/badge.svg)
![Release Charts](https://github.com/greymatter-io/helm-charts/workflows/Release%20Charts/badge.svg)

# Grey Matter Helm Charts

This repository provides Helm charts for configuring and deploying a Grey Matter service mesh into Kubernetes based platforms.

[Helm](https://helm.sh) is required to install the Grey Matter Helm Charts. Follow the Helm [documentation](https://helm.sh/docs/) to get started.

Once Helm is installed, add the Grey Matter repo as follows

```console
helm repo add greymatter https://greymatter-io.github.io/helm-charts
```

You can then run `helm search repo greymatter` to see the charts.

> [Contributing](/docs/CONTRIBUTING.md)

## Quickstart with Grey Matter

The steps below provide a quickstart example to deploy Grey Matter.

### Create Credentials

A Grey Matter LDAP account is still required to pull the images from our Nexus server. Run the following command and provide answers when prompted.

```console
make credentials
```

### Installing

The following set of commands will install Grey Matter using the GitHub hosted Helm Charts.

```console
helm install secrets greymatter/secrets -f credentials.yaml -f global.yaml
helm install spire greymatter/spire --set=global.environment=kubernetes -f global.yaml
helm install fabric greymatter/fabric --set=global.environment=kubernetes -f global.yaml
helm install edge greymatter/edge --set=edge.ingress.type=LoadBalancer -f global.yaml
helm install sense greymatter/sense -f global.yaml --set=global.waiter.service_account.create=false
```

> If you would like to scale to a production ready mesh set global.release.production to true in `global.yaml`

#### Mesh Identity

A `greymatter-mesh-identity-<customer_name>` configmap is created and holds a randomly generated 6 digit alpha numeric code and customer name.  These are used by the makefiles to create the named releases.  Per the Makefiles these helm releases will be of the form `<chart>-<customer_name>-<random_string>`.  This provides developers an extra layer of security for the mesh since the makefile rules load information from the existing mesh. After installation of the service mesh is complete the configmap is deleted.

**To recreate the configmap using helm:**

```console
make restore-identity
```

**Reinstate the configmap manually:**

Create the configmap yaml:

Run `helm ls` and you will see releases of the form `<chart>-<customer_name>-<random_string>`.  Create a yaml from the template below and populate the `<customer_name>` and `<random_string>` accordingly.  Then run `kubectl apply -f <your file>`.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: greymatter-mesh-identity-<customer_name>
  namespace: <namespace>
spec:
  customer: <customer_name>
  rand_identifier: <random_string>
```

> Once the mesh instance configmap is reinstated you will again be able to run make commands against the releases.
> **Note, this does not protect against a user running helm uninstall manually**

### Viewing the Grey Matter Application

At this point, you can verify that Grey Matter was installed successfully by opening your browser and pointing it to `https://localhost:30000` and verify that all six services are running.

![](img/dashboard.png)

## Integration Testing

Integration tests are run automatically upon pull requests; however, you can emulate these same tests on your local machine. In fact, it's encouraged that you do this before you submit a PR. The below procedure assumes that you have cloned this repo and are starting from it's base directory (the same location as this README file).

1. Build the k3d cluster.
    ```console
    make k3d
    ```
2. Configure your credentials (you will need a Grey Matter LDAP username and password).
    ```console
    make credentials
    ```
3. Configure secrets.
    ```console
    make secrets
    ```
4. Run the Grey Matter integration tests.
    ```console
    cd test
    go mod vendor
    go test -v greymatter_integration_test.go
    ```

### Versioning

Grey Matter Helm Charts follow semver principals and allow us to manage active development for current and future releases.  Pre-release charts will have a suffix of `-x` which indicates to helm that this is a prerelease chart.  These are not used for installation or dependency fulfillment unless specifically called out.

Any change to the Helm Chart templates or values files will require the chart version to be incremented in order to pass ci/cd linting.

**General guidance for release/ tag versioning:**

*Increment Major:*
If a helm release can not be upgraded using a `helm upgrade <release_name>`
Adding or major charts

*Increment Minor:*
Addition, removal, substitution of values files and/or templates have changes that make them incompatible with older values files

*Increment Patch:*
Template logic changes which do not result in modifications to values files (are backwards compatible)

### Release Tagging

Releases will be tagged periodically and will be based off the release branch.  For `release-2.4` branch we will tag `2.4.x`.

## More Documentation

Additional information on the Helm Charts and Grey Matter configuration can be found in the links below.

- [Getting Started](https://github.com/greymatter-io/helm-charts/blob/release-2.3docs/Getting%20Started.md)
- [Ingress](https://github.com/greymatter-io/helm-charts/blob/release-2.3docs/Ingress.md)
- [Multi-tenant Helm](https://github.com/greymatter-io/helm-charts/blob/release-2.3docs/Multi-tenant%20Helm.md)
- [Service Accounts](https://github.com/greymatter-io/helm-charts/blob/release-2.3docs/Service%20Accounts.md)
- [Deploy with Minikube](https://github.com/greymatter-io/helm-charts/blob/release-2.3docs/Deploy%20with%20Minikube.md)
- [Deploy with K3d](https://github.com/greymatter-io/helm-charts/blob/release-2.3docs/Deploy%20with%20K3d.md)
- [Upgrade an Existing Grey Matter](https://github.com/greymatter-io/helm-charts/blob/release-2.3docs/Upgrade%20Existing%20Charts.md)
- [SPIRE](https://github.com/greymatter-io/helm-charts/blob/release-2.3docs/SPIRE.md)
- [Control API](https://github.com/greymatter-io/helm-charts/blob/release-2.3docs/Control%20API.md)
- [Caveats and Notes](https://github.com/greymatter-io/helm-charts/blob/release-2.3docs/Caveats%20and%20Notes.md)
- [Generating k8s Configs with Helm](https://github.com/greymatter-io/helm-charts/blob/release-2.3docs/Generating%20k8s%20Configs%20with%20Helm.md)
- [Generating Configuration Docs](https://github.com/greymatter-io/helm-charts/blob/release-2.3docs/Generating%20Configuration%20Docs.md)
- [Upgrading Sidecar Metrics to mTLS](https://github.com/greymatter-io/helm-charts/blob/release-2.3docs/Upgrading%20Sidecar%20Metrics%20to%20mTLS.md)

If at any time you require assistance please contact [Grey Matter Support](https://support.greymatter.io).
