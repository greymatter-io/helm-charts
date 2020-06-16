# Minikube

- [Minikube](#minikube)
  - [Local Minikube Deployment](#local-minikube-deployment)
    - [Prerequisites](#prerequisites)
    - [Quick Start](#quick-start)
      - [Pre-Requisite](#pre-requisite)
    - [Start Minikube](#start-minikube)
      - [Troubleshooting Minikube start](#troubleshooting-minikube-start)
      - [OS X](#os-x)
  - [AWS EC2 Deployment](#aws-ec2-deployment)
  - [Configuration](#configuration)
    - [Copy Files to EC2](#copy-files-to-ec2)
    - [Docker Credentials](#docker-credentials)
  - [Setup Helm](#setup-helm)
  - [Secrets](#secrets)
    - [Ingress](#ingress)
    - [Configure Voyager Ingress](#configure-voyager-ingress)
  - [Install](#install)
    - [Latest Helm charts release](#latest-helm-charts-release)
    - [Local Helm charts](#local-helm-charts)
    - [Verification](#verification)
      - [EC2](#ec2)
    - [Debugging](#debugging)

Minikube allows us to quicky setup a Kubernetes cluster and test drive Grey Matter before deploying to a production environment. We've provided instructions for two scenarios, [Local Minikube Deployment](#local-minikube-deployment) or [AWS EC2 Deployment](#aws-ec2-deployment).

## Local Minikube Deployment

### Prerequisites

You will need the following tools installed (tested on both Mac OS and Linux Ubuntu):

- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)@1.17.0
- [minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/)@1.8.2
- [helm](https://github.com/helm/helm/releases/tag/v3.1.1)@3.1.2
- [virtualbox](https://www.virtualbox.org/wiki/Downloads)@6.0.12

### Quick Start

A couple of Makefile targets provide a fast and easy way to standup Grey Matter on Minikube.

#### Pre-Requisite

- If you don't have the `envsubst` command you can get it with the `gettext` package on [Mac](https://stackoverflow.com/questions/23620827/envsubst-command-not-found-on-mac-os-x-10-8) or Linux. The command is required for using `make credentials`.

Before starting via Minikube you need to supply your credentials for Decipher's Docker registry. These will be your Decipher LDAP credentials: email address and password.

The `fresh` Makefile target runs `make credentials` and `make dev`.

```sh
make fresh
```

You can interactively fillout your credentials with the `credentials` target. This will fillout your docker registry credentials and ask you if you want to setup S3 backing for gm-data. If you chose to have S3 backing you will need to enter a valid access key and secret key.

```sh
make credentials
```

After you have filled out your credentials, you can bring up Minikube and install local Helm charts by running the following:

```sh
make dev
```

You can also install production charts from Decipher's hosted Helm repo by running:

```sh
make prod
```

To spin down minikube.

```sh
make destroy
```

### Start Minikube

To launch a Minikube cluster to a `gm-deploy` VM profile, run the following command:

```sh
minikube start -p gm-deploy --memory 4096 --cpus 4
```

**Note: We specify 4GB of memory and 4 CPUs as this satisfies the minimum resource requirements of Grey Matter.**

You should see a similar output:

```sh
🐳  Preparing Kubernetes v1.17.3 on Docker 19.03.6 ...
🚀  Launching Kubernetes ...
🌟  Enabling addons: default-storageclass, storage-provisioner
⌛  Waiting for cluster to come online ...
🏄  Done! kubectl is now configured to use "gm-deploy"
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
brew reinstall minikube
minikube version
```

## AWS EC2 Deployment

An alternative way to deploy in EC2 is to use the [devinabox](https://github.com/DecipherNow/devinabox) repo which will automate the deployment and configuration of your EC2 instance.

To run the Grey Matter Minikube setup in AWS you will need to spin up a ubuntu18 `t2.xlarge` EC2 instance.

SSH into your EC2 instance:

```sh
ssh -i <path-to-keyfile> ubuntu@<public-dns>
```

Then run the following commands to install dependencies:

```sh

# Install kubectl
sudo apt-get update
sudo snap install kubectl --classic

# Install Docker
sudo apt install docker.io socat -y

# Install minikube
wget https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
chmod +x minikube-linux-amd64
sudo mv minikube-linux-amd64 /usr/local/bin/minikube

# Install Helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

# add helpful aliases
alias minikube='sudo minikube'
alias helm='sudo helm'
alias kubectl='sudo kubectl'
```

Next, start up Minikube. Note that --vm-driver is set to none because AWS EC2 is a virtual machine. There is no need to install a hypervisor like VirtualBox.

```sh
minikube start --vm-driver=none --memory 4096 --cpus 4 -p gm-deploy
```

## Configuration

Our Helm charts can be overriden by custom YAML fiels that are chained together during install. The templates for custom yaml files should follow the pattern of the `<chart>/values.yaml` file inside the chart directory.

### Copy Files to EC2

If deploying to EC2, secure copy these files into the instance.

```sh
scp -i <path-to-keyfile> custom-greymatter-secrets.yaml custom-greymatter.yaml ubuntu@<public-dns>:/home/ubuntu
```

### Docker Credentials

Helm needs valid Docker credentials to pull and run Grey Matter containers. Run `make credentials` to add your Docker credentials. If you need credentials please contact [Grey Matter Support](https://support.greymatter.io).

The `credentials.yaml` file generated should generate your docker credentials in the following form:

```yaml
dockerCredentials:
  - registry: docker.production.deciphernow.com
    email:
    username:
    password:
```

To add credentials for another docker registry, simply add another registry block and its credentials to the list.

## Setup Helm

To install helm:

```bash
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
```

> Note: when using `helm install`, if an install fails the resources deployed may not properly be removed with a `helm uninstall`. Be sure to check for and remove configmaps, secrets, and pvc's manually if an install fails.

## Secrets

To install the helm charts, any certificates or secrets needed for install must be configured and created first.  To install the default secrets, which will provide all necessary certificates and passwords to run the mesh, run the following:

```bash
make credentials
```

This will prompt you for your docker credentials to pull and run Grey Matter containers. It will also provide the optional configuration for AWS S3 for use with Grey Matter Data.

To install the secrets, run:

```bash
make secrets
```

### Ingress

By default, the Helm Charts use nginx ingress in k3d.  If you want to use [a voyager ingress controller](https://appscode.com/products/voyager/), see how to [configure voyager ingress](#configure-voyager-ingress).

See the [Ingress](./Ingress.md) docs for more information on how the ingress objects are created.

### Configure Voyager Ingress

By default, the Helm Charts use nginx ingress in k3d.  If you want to use [a voyager ingress controller](https://appscode.com/products/voyager/), run the following commands and in the `edge/values.yaml` file set `edge.ingress.use_voyager` to true before running `make install`:

```sh
cd voyager
make voyager
```

You should see that the voyager-operator is now running in the namespace `kube-system` by running `kubectl get pods -n kube-system`.

Note that running `kubectl get ingresses` will not list voyager because it uses its own custom resource definition. Instead, use `kubectl get ingress.voyager.appscode.com --all-namespaces` to find it with kubectl. It may take some time before voyager shows up in the result after the installation, so if you get `No resources found.` response, try again a few minutes later.

Describe ingress is also a useful command for debugging:

```sh
kubectl describe ingress.voyager.appscode.com -n <namespace> <ingress-name>
```

To hit our cluster, we can access voyager-edge:

```sh
$ minikube -p gm-deploy service --https=true voyager-edge
|-----------|--------------|--------------------------------|
| NAMESPACE   | NAME           | URL                              |
|-------------|----------------|----------------------------------|
| default     | voyager-edge   | http://192.168.99.102:30001      |
|             |                | http://192.168.99.102:30000      |
| ----------- | -------------- | -------------------------------- |
🎉  Opening kubernetes service  default/voyager-edge in default browser...
🎉  Opening kubernetes service  default/voyager-edge in default browser...
```

Change "`http`" of the URL in the console output to "`https`" (i.e. <https://192.168.99.102:30000> in the above example, then navigate to there in your browser.

You should be prompted for your [Decipher localuser certificate](https://github.com/DecipherNow/grey-matter-quickstarts/tree/master/common/certificates/user) and be taken to the dashboard. Once there, make sure all services are "green" and then pat yourself on the back -- you deployed Grey Matter to Minikube!

To use nginx instead of voyager (the default), you can remove voyager with:

```bash
cd voyager
make remove-voyager
```

See [Ingress](./Ingress.md) for more details.

## Install

### Latest Helm charts release

To install Helm charts representing the latest version of Grey Matter, you'll need to add the Grey Matter Helm repository to your local `helm` CLI. Run the following command, replacing username/password with credentials previously provided to you. These are the same as your Docker credentials.

```sh
helm repo add decipher https://nexus.production.deciphernow.com/repository/helm-hosted --username <username> --password '<password>'
helm repo update
```

Once the repository has successfully been added to your `helm` CLI, and our environment has been changed to`minikube`, you can install Grey Matter from the latest charts.

**Note: Before installing Helm charts it's always prudent to do a dry-run first to ensure your custom YAML is correct. You can do this by adding the `--dry-run` flag to the below `helm install` command. If you receive no errors then you can confidently drop the `--dry-run` flag.**

### Local Helm charts

If you are modifying charts or want to run development versions of charts you'll need to clone this repository.

**Note: if you're installing in EC2 you should follow the previous step to install from the hosted Grey Matter Helm repo.**

```sh
git clone git@github.com:DecipherNow/helm-charts.git
```

Then, you can run the following command to update the local charts one by one and install them.  The `helm install` command for helm3 takes `helm install <release name> <chart> -f <optional config overrides>`.  To install all of the Grey Matter charts at once, run:

```bash
make install
```

### Verification

It may take a few minutes for the installation to become stable. You can watch the status of the pods by running `kubectl get pods -w`.  To specify ingress configuration, see [below](#ingress).

We can run `helm ls` to see all our current deployments and `helm uninstall <release name>` to delete deployments. If you need to make changes, you can run `helm upgrade <release name> <chart> -f <optional config overrides>` to update your release in place.

You should also load the appropriate user p12 file according to the certs you configured when deploying Greymatter. The default certs correspond to the quickstart certificates and the `quickstart.p12` file can be found at `certs/quickstart.p12`. You will want to follow your browser specific instructions to load in this user pki.
[Firefox](https://www.sslsupportdesk.com/how-to-import-a-certificate-into-firefox/) and [Chrome](https://support.globalsign.com/customer/en/portal/articles/1211541-install-client-digital-certificate---windows-using-chrome) instructions.

```sh
NAME   	NAMESPACE	REVISION	UPDATED                                	STATUS  	CHART        	APP VERSION
data   	default  	1       	2020-03-24 12:22:21.014995832 +0000 UTC	deployed	data-3.0.0   	1.2
edge   	default  	1       	2020-03-24 12:21:53.372236561 +0000 UTC	deployed	edge-2.1.6   	1.0.0
fabric 	default  	3       	2020-03-24 15:26:40.20025539 +0000 UTC 	deployed	fabric-3.0.0 	1.2
secrets	default  	1       	2020-03-23 21:27:58.104710704 +0000 UTC	deployed	secrets-1.0.0
sense  	default  	1       	2020-03-24 14:34:27.931518189 +0000 UTC	deployed	sense-3.0.0  	1.2
```

#### EC2

After running the last step where you expose the voyager-edge service, note one of the two ports. We need to expose our instance port to the internet. In your AWS console, navigate to:

EC2 >> (Network & Security) Security Groups >> Your Minikube Security Group >> Inbound

Select the security group you're using and add an inbound rule with custom TCP access to port 30000-30001.

Select **Save**. Navigate back to the AWS instances dashboard and find the `IPv4 Public IP` column. You should be able to see the Grey Matter Dashboard at  `https://<public-ip>:30000`.

### Debugging

If you're not prompted for a certificate when navigating to voyager-edge, or you suspect something went wrong with the installation run the following command to see if there were any errors running pods:

```sh
kubectl get events -w | grep error
```

To see the status of Kubernetes configs, you can access the Kubernetes dashboard running within the Minikube cluster with `minikube dashboard -p gm-deploy`

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
