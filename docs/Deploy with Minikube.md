# Minikube

- [Minikube](#minikube)
  - [Local Minikube Deployment](#local-minikube-deployment)
    - [Prerequisites](#prerequisites)
- [- helm@2.14.3](#helm2143)
    - [Start Minikube](#start-minikube)
      - [Troubleshooting Minikube start](#troubleshooting-minikube-start)
      - [OS X](#os-x)
  - [AWS EC2 Deployment](#aws-ec2-deployment)
  - [Configuration](#configuration)
    - [Copy Files to EC2](#copy-files-to-ec2)
    - [Docker Credentials](#docker-credentials)
  - [Setup Helm](#setup-helm)
    - [Configure Voyager Ingress](#configure-voyager-ingress)
- [You should see that the voyager-operator is now running in the namespace `kube-system`. See `docs/Ingress.md` for more information. Note that running `kubectl get ingresses` will not list voyager because it uses its own custom resource definition. Instead, use `kubectl get ingress.voyager.appscode.com --all-namespaces` to find it with kubectl. Describe ingress is also a useful command for debugging: `kubectl describe ingress.voyager.appscode.com -n <namespace> <ingress-name>`.](#you-should-see-that-the-voyager-operator-is-now-running-in-the-namespace-kube-system-see-docsingressmd-for-more-information-note-that-running-kubectl-get-ingresses-will-not-list-voyager-because-it-uses-its-own-custom-resource-definition-instead-use-kubectl-get-ingressvoyagerappscodecom---all-namespaces-to-find-it-with-kubectl-describe-ingress-is-also-a-useful-command-for-debugging-kubectl-describe-ingressvoyagerappscodecom--n-namespace-ingress-name)
  - [Install](#install)
    - [Latest Helm charts release](#latest-helm-charts-release)
    - [Local Helm charts](#local-helm-charts)
  - [Configure Docker Secrets](#configure-docker-secrets)
- [Helm needs valid docker credentials to pull and run decipher docker containers. Enter in your docker creds into the secret `dockerCredentials` in `greymatter-custom-secrets.yaml`.](#helm-needs-valid-docker-credentials-to-pull-and-run-decipher-docker-containers-enter-in-your-docker-creds-into-the-secret-dockercredentials-in-greymatter-custom-secretsyaml)
    - [Verification](#verification)
    - [Ingress](#ingress)
      - [EC2](#ec2)
    - [Debugging](#debugging)

Minikube allows us to quicky setup a Kubernetes cluster and test drive Grey Matter before deploying to a production environment. We've provided instructions for two scenarios, [Local Minikube Deployment](#local-minikube-deployment) or [AWS EC2 Deployment](#aws-ec2-deployment).

## Local Minikube Deployment

### Prerequisites

You will need the following tools installed (tested on both Mac OS and Linux Ubuntu):

- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)@1.15.3
- [minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/)@1.3.1
<<<<<<< HEAD
- [virtualbox](https://www.virtualbox.org/wiki/Downloads)@6.0.12
- [helm](https://github.com/helm/helm/releases)@2.14.3
=======
- [helm](https://github.com/helm/helm/releases/tag/v2.14.3)@2.14.3
- [virtualbox](https://www.virtualbox.org/wiki/Downloads)@6.0.12
>>>>>>> 6010a70... Merge pull request #275 from DecipherNow/update-minikube-setup

### Start Minikube

To launch a Minikube cluster to a `gm-deploy` VM profile, run the following command:

```sh
minikube start -p gm-deploy --memory 4096 --cpus 4
```

**Note: We specify 4GB of memory and 4 CPUs as this satisfies the minimum resource requirements of Grey Matter.**

You should see a similar output:

```sh
😄  [gm-deploy] minikube v1.3.1 on Ubuntu 18.04
🔥  Creating virtualbox VM (CPUs=4, Memory=4096MB, Disk=20000MB) ...
🐳  Preparing Kubernetes v1.15.2 on Docker 18.09.8 ...
🚜  Pulling images ...
🚀  Launching Kubernetes ...
⌛  Waiting for: apiserver proxy etcd scheduler controller dns
🏄  Done! kubectl is now configured to use "gm-deploy
```

To confirm the status of the Minikube cluster, run the following command:

```sh
minikube status -p gm-deploy
```

You should receive something like the following output:

```sh
host: Running
kubelet: Running
apiserver: Running
kubectl: Correctly Configured: pointing to minikube-vm at 192.168.99.100
```

If you do not then double check that you're using the `-p` flag with the correct profile string.

#### Troubleshooting Minikube start

If you have an older version of Minikube and you receive errors when attempting to start `gm-deploy` then try the below steps.

#### OS X

```sh
rm -rf /usr/local/bin/minikube
rm -rf ~/.minikube
brew update
brew cask reinstall minikube
minikube version
```

## AWS EC2 Deployment

To run the Grey Matter Minikube setup in AWS you will need to spin up a ubuntu18 `t2.xlarge` EC2 instance.

SSH into your EC2 instance:

```sh
ssh -i <path-to-keyfile> ubuntu@<public-dns>
```

Then run the following commands to install dependencies:

```sh

# Install kubectl
sudo apt-get update
curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl

# Install Docker
sudo apt-get update && sudo apt-get install docker.io -y
curl -Lo minikube https://storage.googleapis.com/minikube/releases/v1.3.1/minikube-linux-amd64 && chmod +x minikube && sudo mv minikube /usr/local/bin/

# Install Helm
curl -LO https://git.io/get_helm.sh
chmod 700 get_helm.sh
./get_helm.sh --version v2.14.3

# add helpful aliases
alias minikube='sudo minikube'
alias helm='sudo helm'
alias kubectl='sudo kubectl'
```

Next, start up Minikube. Note that --vm-driver is set to none because AWS EC2 is a virtual machine. There is no need to install a hypervisor like VirtualBox.

```sh
minikube start --vm-driver=none --memory 4096 --cpus 4 -p gm-deploy
```

We will need `socat` as a dependency of Helm:

```sh
sudo apt-get update && sudo apt-get install socat
```

## Configuration

Our Helm charts can be overridden by custom YAML files that are chained together during install. We've provided three examples:

- [greymatter.yaml](../greymatter.yaml) provides a primary set of overrides
- [greymatter-secrets.yaml](../greymatter-secrets.yaml) provides a separate set of overrides specifically for passwords, secrets, and other sensitive data
- [greymatter-minikube.yaml](../greymatter-minikube.yaml) provides Minikube specific configurations but requires no changes
  
Copy these files to `custom-greymatter.yaml`, `custom-greymatter-secrets.yaml` and `custom-greymatter-minikube.yaml`.

### Copy Files to EC2

If deploying to EC2, secure copy these files into the instance.

```sh
scp -i <path-to-keyfile> custom-greymatter-secrets.yaml custom-greymatter.yaml custom-greymatter-minikube.yaml ubuntu@<public-dns>:/home/ubuntu
```

### Docker Credentials

Helm needs valid Docker credentials to pull and run Grey Matter containers. Add your Docker credentials to the `custom-greymatter-secrets.yaml` file. If you need credentials please contact [Grey Matter Support](https://support.deciphernow.com).

```yaml
dockerCredentials:
  registry: docker.production.deciphernow.com
  email:
  username:
  password:
```

## Setup Helm

Before running Helm commands, we need to configure Tiller. This is the Helm server running in the Kubernetes cluster and acts as a endpoint for `helm cli` commands.

```sh
$ helm init
$HELM_HOME has been configured at /home/$USER/.helm.

Tiller (the Helm server-side component) has been installed into your Kubernetes Cluster.

Please note: by default, Tiller is deployed with an insecure 'allow unauthenticated users' policy.
To prevent this, run `helm init` with the --tiller-tls-verify flag.
For more information on securing your installation see: https://docs.helm.sh/using_helm/#securing-your-helm-installation
```

### Configure Voyager Ingress

For Kubernetes, we recommend the [Voyager Ingress Controller](https://appscode.com/products/voyager/), which automatically provisions a load balancer from a variety of supported cloud providers like EKS in AWS. This allows you to access the cluster at the provided load balancer URL.

At present, there's [an issue](https://github.com/appscode/voyager/issues/1415) specifying Voyager as a dependency so we need to manually configure Voyager ingress as a prerequisite. This can be done with following commands:

```sh
export PROVIDER=minikube
helm repo add appscode https://charts.appscode.com/stable/
helm repo update
helm install appscode/voyager --name voyager-operator --version 10.0.0 \
  --namespace kube-system \
  --set cloudProvider=$PROVIDER \
  --set enableAnalytics=false \
  --set apiserver.enableAdmissionWebhook=false
...
NOTES:
Set cloudProvider for installing Voyager

To verify that Voyager has started, run:

  kubectl --namespace=kube-system get deployments -l "release=voyager-operator, app=voyager"
```

<<<<<<< HEAD
You should see that the voyager-operator is now running in the namespace `kube-system`. See `docs/Ingress.md` for more information. Note that running `kubectl get ingresses` will not list voyager because it uses its own custom resource definition. Instead, use `kubectl get ingress.voyager.appscode.com --all-namespaces` to find it with kubectl. Describe ingress is also a useful command for debugging: `kubectl describe ingress.voyager.appscode.com -n <namespace> <ingress-name>`.
=======
You should see that the voyager-operator is now running in the namespace `kube-system`.

Note that running `kubectl get ingresses` will not list voyager because it uses its own custom resource definition. Instead, use `kubectl get ingress.voyager.appscode.com --all-namespaces` to find it with kubectl. It may take some time before voyager shows up in the result after the installation, so if you get `No resources found.` response, try again a few minutes later.

Describe ingress is also a useful command for debugging:

```sh
kubectl describe ingress.voyager.appscode.com -n <namespace> <ingress-name>
```

See [Ingress](./docs/Ingress.md) for more details.

## Install

### Latest Helm charts release
>>>>>>> 6010a70... Merge pull request #275 from DecipherNow/update-minikube-setup

To install Helm charts representing the latest version of Grey Matter, you'll need to add the Grey Matter Helm repository to your local `helm` CLI. Run the following command, replacing username/password with credentials previously provided to you. These are the same as your Docker credentials.

```sh
helm repo add decipher https://nexus.production.deciphernow.com/repository/helm-hosted --username <username> --password '<password>'
helm repo update
```

Once the repository has successfully been added to your `helm` CLI, you can install Grey Matter from the latest charts.

**Note: Before installing Helm charts it's always prudent to do a dry-run first to ensure your custom YAML is correct. You can do this by adding the `--dry-run` flag to the below `helm install` command. If you receive no errors then you can confidently drop the `--dry-run` flag.**

```sh
helm install decipher/greymatter -f custom-greymatter.yaml -f custom-greymatter-secrets.yaml -f custom-greymatter-minikube.yaml --name gm
```

### Local Helm charts

If you are modifying charts or want to run development versions of charts you'll need to clone this repository.

<<<<<<< HEAD
## Configure Docker Secrets

Helm needs valid docker credentials to pull and run decipher docker containers. Enter in your docker creds into the secret `dockerCredentials` in `greymatter-custom-secrets.yaml`.
=======
**Note: if you're installing in EC2 you should follow the previous step to install from the hosted Grey Matter Helm repo.**

```sh
git clone git@github.com:DecipherNow/helm-charts.git
```

Then you'll need to modify the repository paths in `requirements.yaml` to point to the relative chart paths of this GitHub project.
>>>>>>> 6010a70... Merge pull request #275 from DecipherNow/update-minikube-setup

```yaml
dependencies:
  - name: dashboard
    version: '2.0.1'
    repository: 'file://../dashboard'
```

Then you can run the following commands to update the local charts and then install them.

```sh
helm dep up greymatter
helm install greymatter -f custom-greymatter.yaml -f custom-greymatter-secrets.yaml -f custom-reymatter-minikube.yaml --name gm
```

The `helm dep up greymatter` command will create a `./greymatter/charts` directory with tarballs of each sub-chart that the parent `greymatter` chart will use to install Grey Matter.

### Verification

It may take a few minutes for the installation to become stable. You can watch the status of the pods by running `kubectl get pods -w -n default`. Before attempting to view the Grey Matter dashboard you'll need to setup ingress in the next section.

We also have the option to specify:

- "--replace" will replace an existing deployment
- "--dry-run" will print all Kubernetes configs to stdout

We can run `helm ls` to see all our current deployments and `helm delete --purge $DEPLOYMENT` to delete deployments. If you need to make changes, you can run `helm upgrade gm deciperhnow/greymatter -f custom-greymatter.yaml -f custom-greymatter-secrets.yaml -f custom-greymatter-minikube.yaml` to update your release in place.

```sh
NAME                    REVISION        UPDATED                         STATUS          CHART                   APP VERSION     NAMESPACE  
gm                      1               Thu Sep 12 11:25:43 2019        DEPLOYED        greymatter-2.1.0-dev    1.0.2-dev       default
voyager-operator        1               Thu Sep 12 11:19:01 2019        DEPLOYED        voyager-10.0.0          10.0.0          kube-system
```

### Ingress

There are two pods which control our ingress:

- `edge` validates client-facing certificates and gets routing rules from `gm-control-api`.
- `voyager-edge` is our ingress controller. Edge isn't exposed to the outside world, and in a real deployment we need to tie our cluster ingress to an IP address. This points to `edge`.

To hit our cluster, we can access voyager-edge:

```sh
$ minikube -p gm-deploy service --https=true voyager-edge
|-----------|--------------|--------------------------------|
| NAMESPACE   | NAME           | URL                              |
| ----------- | -------------- | -------------------------------- |
| default     | voyager-edge   | http://192.168.99.102:31581      |
|             |                | http://192.168.99.102:31975      |
| ----------- | -------------- | -------------------------------- |
🎉  Opening kubernetes service  default/voyager-edge in default browser...
🎉  Opening kubernetes service  default/voyager-edge in default browser...
```

Change "`http`" of the URL in the console output to "`https`" (i.e. <https://192.168.99.102:31581> in the above example - the port number is probably different), then navigate to there in your browser.

You should be prompted for your [Decipher localuser certificate](https://github.com/DecipherNow/grey-matter-quickstarts/tree/master/common/certificates/user) and be taken to the dashboard. Once there, make sure all services are "green" and then pat yourself on the back -- you deployed Grey Matter to Minikube!!

#### EC2

After running the last step where you expose the voyager-edge service, note one of the two ports. We need to expose our instance port to the internet. In your AWS console, navigate to:

EC2 >> (Network & Security) Security Groups >> Your Minikube Security Group >> Inbound

Select the security group you're using and edit the following:

| Parameter      | Value                                                |
| -------------- | ---------------------------------------------------- |
| **Type**       | TCP                                                  |
| **Protocol**   | 30263 (the voyager-edge port from the previous step) |
| **Port Range** | Custom                                               |
| **Source**     | 0.0.0.0/0  (Accessible via the internet)             |

Select **Save**. Navigate back to the AWS instances dashboard and find the `IPv4 Public IP` column. You should be able to see the Grey Matter Dashboard at  `https://<public-ip>:<voyager-edge-port>`.

### Debugging

To see the status of Kubernetes configs, you can access the Kubernetes dashboard running within the Minikube cluster with `minikube dashboard`

To debug the mesh, you can access the Envoy admin UI for the edge proxy by running:

```sh
kubectl port-forward $(kubectl get pods --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}' | grep ^edge) 8088:8001
```

Then curl the API to see a list of endpoints you can leverage:

```sh
curl localhost:8088/help
```

For example, if you want to see the status of upstream clusters in the mesh run the following command:

```sh
curl localhost:8088/clusters
```
