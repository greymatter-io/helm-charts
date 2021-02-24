# Deploying Keycloak

## Setup Grey Matter

### Install Cluster Using Buttermilk Sky

```bash
bs create-kops-cluster --name $NAME --vpc dev2 --publicSubnets
```

See [runbook](https://github.com/greymatter-io/buttermilk-sky/blob/master/docs/content/runbooks/kops_cluster.md) for more information


### Install helm charts @release-2.3

```bash
git fetch && git checkout origin/release-2.3
make secrets
make install
```

## Setup Keycloak

### Install Bitnami Chart

```bash
helm install keycloak bitnami/keycloak
```

Once installed, get the username and password for the keycloak admin:
```bash
echo Username: user
echo Password: $(kubectl get secret --namespace default keycloak -o jsonpath="{.data.admin-password}" | base64 --decode)
```

### Add Users

TODO

### Add Edge Client

TODO


## Configure Edge

### TLS

TODO

### Listener

- add in `clientId` and `clientSecret`
- `provider` and `serviceUrl`
- port-forwar and update