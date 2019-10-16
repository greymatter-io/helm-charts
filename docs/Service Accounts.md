# Service Accounts

Various services in the mesh require Kubernetes Service Accounts to function. These are:

- `gm-control` - requires read access to Kubernetes Pods for service discovery
- `prometheus` - requires read access to Kubernetes Pods to scrape metrics
- `waiter` - various services use the `deciphernow/k8s-waiter` image as an InitContainer, which waits for a given service to have "ready" endpoints using the Kubernetes Endpoints API. This allows you to use readiness checks to define service dependencies in an idiomatic way. Requires read access to Kubernetes Endpoints. The services which use this InitContainer are:
  - `gm-catalog` - waits for `gm-control` to be up
  - `gm-slo` - waits for Postgres to be up
  - `gm-control` - waits for `gm-control-api` to be up - see above, also needs access to pods, so make sure you create one service account for this.
  - `gm-control-api-init` - waits for `gm-control-api` to be up to bootstrap the mesh configuration

The waiter service account can be created automatically with `.Values.global.waiter.serviceAccount.create` set to `true`. Otherwise, all services that need access to a waiter service account will use the one specified by `.Values.global.waiter.serviceAccount.name`

All of the service accounts needed for Grey Matter can either be created automatically by Helm (if it has the appropriate permissions), or be created manually by a cluster admin. This is configured in the `serviceAccount` map that is found at different locations for various service accounts, which always looks like this:

```yaml
serviceAccount:
  create: true
  name: waiter-sa
```

If `create` is true, Helm will create a service account with the specified `name`. If `create` is false, the Grey Matter cluster expects you to have already created a service account with the appropriate permissions with the specified name. To figure out what permissions you need to give to a given service account, you will need to look at the `<something>-role.yaml` and `<something>-rolebinding.yaml` in the `templates` directory that corresponds to a given service account.

The following list gives the service that needs a service account along with the Helm values key where you can configure the service account settings as shown above:

- `gm-control` - control subchart, `.Values.control.serviceAccount`
- `prometheus` - dashboard subchart, `.Values.prometheus.serviceAccount`
- `waiter` - greymatter chart - `.Values.global.waiter.serviceAccount`
- `spire-agent` - spire subchart - `.Values.spire.agent.serviceAccount`
- `spire-server` - spire subchart - `.Values.spire.server.serviceAccount`

If you're deploying into an environment where Tiller doesn't have sufficient permissions to create service accounts, you'll need to apply the [greymatter-service-accounts.yaml](../greymatter-service-accounts.yaml) file.

1. In your custom values file be sure to prevent Tiller from attempting to create the accounts. All occurrences of `serviceAccount.create` should be set to `false`.

    ```yaml
    waiter:
      serviceAccount:
        create: false
    ...
    control:
      serviceAccount:
        create: false
    ...
    prometheus:
      serviceAccount:
        create: false
    ```

2. Change all occurrences of `namespace` in `greymatter-service-accounts.yaml` to the namespace you're deploying to.
3. Creat the service accounts by applying the `greymatter-service-accounts.yaml` as a cluster admin.

    ```sh
    oc apply -f greymatter-service-accounts.yaml
    ```

[Multi-tenant Helm guide](./Multi-tenant%20Helm.md) provides further details on deploying Tiller securely.
