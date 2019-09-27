# Multi-tenant Helm Installation

By default, Helm will create a Tiller server that has cluster-admin access to the Kubernetes cluster. This poses a security risk in a multi-tenant cluster as it exposes a potential attack point to a service with elevated permissions. The workaround is to deploy a Tiller service to each namespace where Helm will be used. First a system account needs to be created that has a reduced permissions set, limiting the vulnerability.

## Create the Service Account

Tiller needs a service account to manage services. The `tiller-manager` Role can only be created by a cluster admin due to it's requirements at the cluster level. The following example will create a service account, role and role binding. For the purpose of this example, we will default to the `greymatter` namespace. This should be replaced with your own unique namespace and be run by a namespace admin.

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tiller
  namespace: greymatter
kind: Role
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: tiller-manager
  namespace: greymatter
rules:
  - apiGroups: ['', 'extensions', 'apps', 'route.openshift.io', 'batch']
    resources: ['*']
    verbs: ['*']
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: tiller-binding
  namespace: greymatter
subjects:
  - kind: ServiceAccount
    name: tiller
    namespace: greymatter
roleRef:
  kind: Role
  name: tiller-manager
  apiGroup: rbac.authorization.k8s.io
```

If deploying to OpenShift, the following template can be used

```yaml
apiVersion: v1
kind: Template
metadata:
  name: tiller-service-setup
  annotations:
    openshift.io/display-name: "Tiller-Service-Setup"
  description: "Tiller Service User Setup"
  iconClass: "pficon-zone"
objects:
  - apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: tiller
      namespace: ${NAMESPACE}
  - kind: Role
    apiVersion: rbac.authorization.k8s.io/v1beta1
    metadata:
      name: tiller-manager
      namespace: ${NAMESPACE}
    rules:
    - apiGroups: ['', 'extensions', 'apps', 'route.openshift.io', 'batch']
      resources: ['*']
      verbs: ['*']
  - kind: RoleBinding
    apiVersion: rbac.authorization.k8s.io/v1beta1
    metadata:
      name: tiller-binding
      namespace: ${NAMESPACE}
    subjects:
      - kind: ServiceAccount
        name: tiller
        namespace: ${NAMESPACE}
    roleRef:
      kind: Role
      name: tiller-manager
      apiGroup: rbac.authorization.k8s.io
parameters:
- description: Name of target namespace
  name: NAMESPACE
  value: 'greymatter'
```

Copy the above YAML into `service-accounts.yaml` and then run the following command:

```sh
oc process -f service-accounts.yaml | oc apply -f -
```

## Initialize Helm for the namespace

Helm needs to be initialized to function, but unlike a typical initialization, we now need to provide the namespace and service account that Helm and Tiller will use. The following command initializes Helm in the `greymatter` namespace using the `tiller` service account.

If you need to add the Grey Matter Helm repo, follow the "Latest Helm charts release" in the [Getting Started](./docs/Getting%20Started.md) guide.

```sh
helm init --tiller-namespace greymatter --service-account tiller
```

## Install with Helm

Now, when you invoke `helm` commands you'll need to specify the `--tiller-namespace`.

```sh
helm install decipher/greymatter -f custom1.yaml -f custom2.yaml --name greymatter --tiller-namespace greymatter
```

## Remove Tiller

One of the ways to protect your deployment is to remove the Tiller service when all deploys are complete. This removes the Kubernetes service that may be targeted. The following command removes the Tiller service from the `greymatter` namespace.

```sh
oc delete deployment Tiller-deploy --namespace greymatter
```

**Note: This above command will also work with kubectl.**

## Re-deploy Tiller

More than likely you will need to update or deploy additional services. To do this, you’ll need to add your Tiller service back to your namespace. The following command will redeploy a Tiller service to the namespace `greymatter`:

```sh
helm init --upgrade --tiller-namespace greymatter --service-account tiller
```

## Change Tiller Version

For Tiller and Helm to work together they need to have compatible versions. The following command is an easy way to check compatibility:

```sh
helm version --tiller-namespace greymatter
```

Results:

```sh
Client: &version.Version{SemVer:"v2.14.2", GitCommit:"a8b13cc5ab6a7dbef0a58f5061bcc7c0c61598e7", GitTreeState:"clean"}
Server: &version.Version{SemVer:"v2.14.0", GitCommit:"05811b84a3f93603dd6c2fcfe57944dfa7ab7fd0", GitTreeState:"clean"}
```

Both the major and minor versions need to match for Tiller and Helm to work. If they do not match then Tiller will need to be deleted, the Helm version will need to be changed to the appropriate release, then Tiller will need to be re-deployed.

## Miscellaneous

### Environments with Limits

If you encounter an error deploying Tiller because the cluster is enforcing limits, run the following command to add limits to the Tiller deployment in the namespace `greymatter`:

```sh
oc set resources deployment tiller-deploy --limits=cpu=10m,memory=20Mi -n greymatter
```

**Note: This above command will also work with kubectl.**

## Using a Unique Helm Home

Similar to `kubectl`, Helm stores its client files in a directory on your machine. It defaults to `~/.helm`, but this can be modified. If you are using Helm to deploy to multiple Kubernetes clusters, you may find this useful. You can set `HELM_HOME` to a location of your choosing for storage of the client files.

```sh
export HELM_HOME=$(pwd)/.helm
```

## Using a Unique Tiller Deployment

In rare instances, we may need to deploy Helm using a bastion host, or using a specifically defined host/port combination. In this case, we can set `HELM_HOST` to the location and port where Tiller can be found.

```sh
export HELM_HOST=localhost:44134
```
