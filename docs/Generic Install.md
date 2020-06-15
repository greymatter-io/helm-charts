# Installing

This is a generic guide on installing from local or hosted charts.

If you have your environment running and ready for install, make any custom configurations to the deployment as follows:

Global values can be specified in the `global.yaml` file. Important configurations are:

- `global.environment` (kubernetes, openshift, eks, etc)
- `global.spire.enabled` indicating whether or not to use spire
- `global.control.additional_namespaces` should be used if gm-control & prometheus will need to discover from namespaces other than the release namespace that the fabric chart will be deployed into

Certificates should be specified in `secrets/values.yaml`.  The `secrets` chart will generate kubernetes secrets using these values. You can also run `make credentials` from the root directory to generate a file with docker registry and aws credentials for data.

Configurations for the fabric chart (control, control-api, and jwt-security) should be specified in `fabric/values.yaml`.

Configurations for the edge proxy (ingress, etc) should be specified in `edge/values.yaml`.

Configurations for the data chart should be specified in `data/values.yaml`.

Configurations for the sense chart (catalog, slo, and dashboard) should be specified in `sense/values.yaml`.

## Install with hosted charts

Once you have the desired configurations, and account credentials to access to [Deciphers Nexus Repository](https://nexus.production.deciphernow.com/#browse/welcome), you can install using the hosted helm charts:

```bash
helm repo add decipher https://nexus.production.deciphernow.com/repository/helm-hosted --username 'YOUR USERNAME' --password 'YOUR PASSWORD'
helm repo update
```

### 1. Install secrets

Using the `credentials.yaml` file you generated with `make credentials`, or by editing the `secrets/values.yaml` section under `dockerCredentials` to look something like this:

```yaml
dockerCredentials:
  - registry: docker.production.deciphernow.com
  - email: <nexus-email>
  - username: <nexus-email>
  - password: <nexus-password>
```

you can install secrets (if you did not generate `credentials.yaml` take the flag off below):

```bash
helm install secrets decipher/secrets -f global.yaml -f secrets/values.yaml -f credentials.yaml
```

If youre installing different Grey Matter components to different namespaces you will need to generate secrets by adding the flag `-n <desired-namespace>` and rerunning for each namespace.

### 2. Install SPIRE

If you are not using SPIRE, skip this step (and make sure `global.spire.enabled` is false in your `global.yaml` file).

To install the SPIRE server:

```bash
helm install server decipher/server -f global.yaml
```

This will install spire into the `spire` namespace. Run `kubectl get pods -n spire -w` and wait until the server containers are `2/2`.

> NOTE: The SPIRE server must be fully running before installing any other component.

Once the server is running, install the agents:

```bash
helm install agent decipher/agent -f global.yaml
```

### 3. Install Grey Matter

Now, to install the core Grey Matter charts run the following. If you made changes to the `<chart>/values.yaml` files for any specific chart, add the flag `-f <chart>/values.yaml` to its install command. If you would like to deploy any or all charts to a namespace other than `default`, also add the flag `-n <desired-namespace>` pointing to the already existing namespace.

> **Note** that if you edit the global values *within* a `<chart>/values.yaml`, the values from the file passed with `-f` second in the order will override the values of the first file passed.

```bash
helm install fabric decipher/fabric -f global.yaml
helm install edge decipher/edge -f global.yaml
helm install data decipher/data -f global.yaml --set=global.waiter.service_account.create=false
helm install sense decipher/sence -f global.yaml --set=global.waiter.service_account.create=false
```

> Note: the additional flag `--set=global.waiter.service_account.create=false` on the data and sense install's is necessary because of conflicting resources already created in the fabric install.

Once all of the pods come up, you can check your ingress for the dashboard.

## Install with the local charts

For development, or to deploy a branch with changes made within the charts themselves - follow the same instruction as [above](#install-with-hosted-charts) but instead of following the pattern `helm install <release> decipher/<chart> <flags>`, run:

```bash
helm dep up <chart>
helm install <release> <chart> <flags>
```
