# Service Accounts

Various services in the mesh require Kubernetes Service Accounts to function.  There are three service accounts that are necessary to run all four Grey Matter charts together, `control-sa`, `prometheus-sa`, and `waiter-sa`. `control-sa` is required by Grey Matter Control, `prometheus-sa` is required by Grey Matter Dashboard, and `waiter-sa` is required by several subcharts.

The Grey Matter subcharts require the following service accounts:

- Fabric
  - control
    - requires `control-sa`
    - requires `waiter-sa`
  - control-api
    - requires `waiter-sa`
- Edge
- Data
  - data
    - requires `waiter-sa` 
  - jwt
  - jwt-gov
- Sense
  - catalog
    - requires `waiter-sa`
  - slo
    - requires `waiter-sa`
  - dashboard
    - requires `prometheus-sa`

There are two ways to create the necessary service accounts and their corresponding Roles, ClusterRoles, RoleBinding's and ClusterRoleBindings.

## Using Helm to Create the Service Accounts

The first way to generate the necessary service accounts to run Grey Matter on install is to configure the `<chart>/values.yaml` files.

Each of the Grey Matter charts has the ability to create the necessary service accounts on install. In each `<chart>/values.yaml` file that requires the `waiter-sa` service account has the following configuration options:

```yaml
global:
  waiter:
    image: deciphernow/k8s-waiter:latest
    service_account:
      create: true
      name: waiter-sa
```

Set `.Values.global.waiter.service_account.create` to true to create the `waiter-sa` in the necessary charts.

Keep in mind that because the `waiter-sa` service account is used by multiple charts, `.Values.global.waiter.service_account.create` should only be set to true in one of the charts being deployed. 

For example, if you install the Fabric chart first, make sure `.Values.global.waiter.service_account.create` is true.  Then, when installing the other charts, add the flag `--set=global.waiter.service_account.create=false` in order to prevent helm from trying to generate the same service account twice.

Additionally, the `sense/values.yaml` has the following configuration option for the dashboard subchart:

```yaml
dashboard:
  prometheus:
    service_account:
      create: true
      name: prometheus-sa
```

and the `fabric/values.yaml` has the following configuration option for the control subchart:

```yaml
control:
  control:
    service_account:
      create: true
      name: control-sa
```

## Manually Creating the Service Accounts

Another way to create the service accounts necessary to run Grey Matter is to use the `greymatter-service-accounts.yaml` file.  Edit the file to use the correct `namespace` for each object to be created, and `kubectl apply -f greymatter-service-accounts.yaml` to create them.  Then, to install each chart, run the following:

```bash
helm install <release-name> <chart> --set=global.waiter.service_account.create=false --set=dashboard.prometheus.service_account.create=false --set=control.control.service_account.create=false
```

## Creating Service Accounts for Other Namespaces

Grey Matter has the ability to monitor services deployed in any namespace in Kubernetes, but the service accounts need access to the namespace.  In order to enable a service account to have access to another namespace, a new `Role` and `RoleBinding` need to be created.  This is a manual step that must be done for each namespace that you will be deploying Grey Matter monitored services.

Here is an example of a new `Role` and `RoleBinding` for the `waiter-sa` service account.  It assumes that the new namespace is called `services`.

```yaml
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: waiter-sa-role
  namespace: services
rules:
  - apiGroups: ['']
    resources: ['endpoints']
    verbs: ['get', 'list', 'watch']
```

```yaml
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: waiter-sa-rolebinding
  namespace: services
subjects:
  - kind: ServiceAccount
    name: waiter-sa
    namespace: greymatter
roleRef:
  kind: Role
  name: waiter-sa-role
  apiGroup: rbac.authorization.k8s.io
```

Notice that only the `metadata.namespace` field needs to be updated for both files.  The `waiter-sa` service account has already been created in the `greymatter` namespace and a new `Role` and `RoleBinding` can leverage the existing service account.  

If you manually created the service accounts using the `greymatter-service-accounts.yaml` file referenced above, you will only need to perform this action for the `waiter-sa` account. If `control-sa` and `prometheus-sa` were created as non-Cluster roles (ie: not `ClusterRole` and `ClusterRoleBinding`), you will need to perform the same steps for those accounts as well.

Permissions can be verified using the following command

```sh
> kubectl auth can-i list endpoints -n services --as system:serviceaccount:greymatter:waiter-sa
yes
```