# Service Accounts

Various services in the mesh require Kubernetes Service Accounts to function. These are:

- `control` - requires read access to kubernetes Pods for service discovery
- `prometheus` - also requires read access to kubernetes Pods to scrape metrics
- `waiter` - various services use the `deciphernow/k8s-waiter` image as an InitContainer, which waits for a given service to have "ready" endpoints using the Kubernetes Endpoints API. This allows you to use readiness checks to define service dependencies in an idiomatic way. Requires read access to kubernetes Endpoints. The services which use this initContrainer are:
  - `catalog` - waits for `gm-control` to be up
  - `slo` - waits for postgres to be up
  - `control` - waits for `gm-control-api` to be up - see above, also needs access to pods, so make sure you create one serviceaccount for this.
  - `gm-control-api-init` - waits for `gm-control-api` to be up to bootstrap the mesh configuration

The waiter service account can be created automatically with `.Values.global.waiter.serviceAccount.create` set to `true`. Otherwise, all services that need access to a waiter service account will use the one specified by `.Values.global.waiter.serviceAccount.name`

All of the service accounts needed for Grey Matter can either be created automatically by Helm (if it has the appropriate permissions), or be created manually by a cluster admin. This is configured in the `serviceAccount` map that is found at different locations for various service accounts, which always looks like this:

```yaml
serviceAccount:
    create: true
    name: waiter-sa
```

If `create` is true, Helm will create a ServiceAccount with the specified `name`. If `create` is false, the Grey Matter cluster expects you to have already created a ServiceAccount with the appropriate permissions with the specified name. To figure out what permissions you need to give to a given ServiceAccount, you will need to look at the `<something>-role.yaml` and `<something>-rolebinding.yaml` in the `templates` directory that corresponds to a given serviceAccount.

The following list gives the service that needs a serviceAccount along with the Helm values key where you can configure the serviceAccount settings as shown above:

- `control` - control subchart, `.Values.control.serviceAccount`
- `prometheus` - dashboard subchart, `.Values.prometheus.serviceAccount`
- `waiter` - greymatter chart - `.Values.global.waiter.serviceAccount`
- `spire-agent` - spire subchart - `.Values.spire.agent.serviceAccount`
- `spire-server` - spire subchart - `.Values.spire.server.serviceAccount`

If you're deploying into an environment where Helm/Tiller doesn't have sufficient permissions to create service accounts, you'll need to apply the [greymatter-service-accounts.yaml](../greymatter-service-accounts.yaml) file first.  The user to apply this file will need to have sufficient permissions to create accounts.  The custom values file will also need to be updated to ensure Helm doe not try to create the accounts.
