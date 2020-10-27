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
$ helm install secrets greymatter/secrets -f credentials.yaml -f global.yaml
$ helm install spire greymatter/spire --set=global.environment=kubernetes -f global.yaml
$ helm install fabric greymatter/fabric --set=global.environment=kubernetes -f global.yaml
$ helm install edge greymatter/edge --set=edge.ingress.type=LoadBalancer -f global.yaml
$ helm install sense greymatter/sense -f global.yaml --set=global.waiter.service_account.create=false
```

### Viewing the Grey Matter Application

At this point, you can verify that Grey Matter was installed successfully by opening your browser and pointing it to `https://localhost:30000` and verify that all six services are running.

![](img/dashboard.png)

## More Documentation

Additional information on the Helm Charts and Grey Matter configuration can be found in the links below.

- [Getting Started](docs/Getting%20Started.md)
- [Ingress](docs/Ingress.md)
- [Multi-tenant Helm](docs/Multi-tenant%20Helm.md)
- [Service Accounts](docs/Service%20Accounts.md)
- [Deploy with Minikube](docs/Deploy%20with%20Minikube.md)
- [Deploy with K3d](docs/Deploy%20with%20K3d.md)
- [Upgrade an Existing Grey Matter](docs/Upgrade%20Existing%20Charts.md)
- [SPIRE](docs/SPIRE.md)
- [Control API](docs/Control%20API.md)
- [Caveats and Notes](docs/Caveats%20and%20Notes.md)
- [Generating k8s Configs with Helm](docs/Generating%20k8s%20Configs%20with%20Helm.md)
- [Generating Configuration Docs](docs/Generating%20Configuration%20Docs.md)
- [Upgrading Sidecar Metrics to mTLS](docs/Upgrading%20Sidecar%20Metrics%20to%20mTLS.md)

If at any time you require assistance please contact [Grey Matter Support](https://support.greymatter.io).
