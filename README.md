# Helm Charts for Grey Matter

## Overview
This repository provides helm charts for easily configuring and deploying every component in the Grey Matter service mesh to both Openshift and Kubernetes environments. 

## Getting Started

Each step is important  so that helm has all the information it needs to finally deploy Grey Matter.

1. Setup the prerequisites (helm, openshift, kubernetes, AWS S3, and docker)
2. Setup your custom values (domain, environment, S3 creds)
3. Add the Decipher helm repository to your local helm CLI
4. Install your Helm chart dependencies
5. Deploy the helm chart

## 1. Prerequisites

### Helm

- Helm CLI version 2.13.1 or greater

To install Helm on MacOS you can run `brew install kubernetes-helm`, or use [other install methods](https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet#links) on other platforms.

### OpenShift

If you are using an OpenShift environment, you need to:

- Login to your environment (in Decipher's case `development.deciphernow.com`)

Run `oc login`, which will respnd with something along the lines of

```Login failed (401 Unauthorized)
Verify you have provided correct credentials.
You must obtain an API token by visiting https://development.deciphernow.com:8443/oauth/token/request
```

Follow the link provided and use the provided comand to login. The command will look something like:
  `oc login --token=<some_crazy_long_and_random_string> --server=https://development.deciphernow.com:8443`

### AWS

AWS is used for configuring Exhibitor, the Zookeeper-based service discovery system, along with GM Data. If exhibitor does not have valid S3 credentials, the cluster will not come up.

Make sure you have an:

- Account access key
- Secret key
- Ability to create a s3 bucket
- OR Access to an existing bucket (e.g. `decipher-quickstart-helm`)

### Docker Credentials

You need valid Docker credentials which have access to the Decipher repository in order to pull all the Grey Matter images.

- The URL of the docker registry containing GM images 
- Access to the images in that registry
- Account Email
- Account Username/pass

## 2. Helm Values Configuration

Each Helm chart has a `values.yaml` file which specifies the default values used to generate/template the final Kubernetes resource files with YAML.

These values can be overwritten by you, the user, and in fact, several of them **MUST** be configured for Grey Matter to deploy sucessfully. 

We've provided an `example-custom.yaml` file that showcases the general structure of a Helm values file and shows how top-level keys are passed down to dependency subcharts. Most of these keys you don't need to worry about.

However, you **need** to configure the:
 1. Basic values
 2. Voyager `cloudProvider`
 3. and AWS + Docker credentials


#### Basics
Firstly, setup the basic information about your deployment by editing the following:

```yaml
global:
  environment: # openshift or kubernetes
  domain: 
  route_url_name:
```

The final domain of your GM deployment will be located at `<route_url_name>.<kubernetes_namespace>.<domain>`. This can be changed by setting `remove_namespace_from_url` to `true` which would remove the Kubernetes namespace from the URL.

For example, with

```yaml
domain: deciphernow.com
route_url_name: greymatter
# and by default, but configurable when deploying via helm:
namespace: default
```

The URL would be `greymatter.default.deciphernow.com`. 

#### Voyager
Next, you need to set the type of environment you are in and pass it to the Voyager edge proxy.
Edit `cloudProvider` in the following to be one of the [supported providers](https://appscode.com/products/voyager/7.1.1/setup/install/#using-script)

```yaml
voyager:
  cloudProvider: # aws | gcp | gks | azure | aks | baremetal | some others
  enableAnalytics: false
```

More details on Voyager are in [`edge/README.md`](edge#setting-up-the-ingress).

#### Credentials
Finally, you need to set the values for all the AWS and Docker credentials you located above. Fill out all the values for the following top-level keys:

```yaml
dockerCredentials: ...
exhibitor: ...
 
# Optionally:
data: ...
```

#### NOTE: Certificates

You may notice a huge section of the file which is just various TLS certificates with public and private keys. These are used in many services, including JWT, the sidecar, and the edge.

To actually access the Grey Matter Dashboard or any other service in the cluster, your request will pass through the edge service, which performs mTLS or Mutual TLS. This means that both the client and the server must authenticate themselves, and that your browser (or other HTTPS client e.g. `curl`) will need to have the appropriate certificates loaded.

To keep things simple, the `example-custom.yaml` uses the same certificates as those from `common/certificates/user/quickstart.p12` in the [DecipherNow/grey-matter-quickstart](https://github.com/DecipherNow/grey-matter-quickstarts) repository. 

If you load `quickstart.p12` into your browser, when you access the GM Dashboard, you'll be prompted to use that certificate to verify yourself, which you should do to gain access.

#### NOTE: Single-service deployments

If you want to deploy a Helm chart for a single service without the entire service mesh, you need to make sure that your `custom.yaml` `globals.sidecar.envvars` key contains all of the necessary global defaults for the sidecar environment variables. You can just copy these values from our `example-custom.yaml` file. Otherwise, the sidecar for the single service will only contain the environment variables that are different for that service. This will most likely break your sidecar installation, so be sure that you set these values.

## 3. Add the Decipher Helm Repo to Helm

You will need to add the Decipher Helm repo to helm running on your machine. Run the following command, replacing the username and password with the Decipher LDAP credentials you've been provided.

```bash
helm repo add decipher https://nexus.production.deciphernow.com/repository/helm-hosted --username <ldap username> --password <ldap password>
```

This allows you to install the dependency charts of Grey Matter.


## 4. Install Dependencies

If you are deploying a chart like `greymatter` with dependencies defined in `requirements.yaml`, you need to run:

```bash
helm dep up greymatter
```

This command will create a `charts/` directory with tarballs of the child charts that the parent chart will use. After the charts directory is populated then you will be able to run a `helm install greymatter <options>`

By default the greymatter dependencies will be pulled from a repository as defined in `requirements.yaml`:

```yaml
dependencies:
- name: dashboard
  version: "1.0.0"
  repository: "https://nexus.production.deciphernow.com/repository/helm-hosted"
```

If you want to make changes to charts you will need to change the requirements.yaml file to point to the appropriate directory:

```yaml
dependencies:
- name: dashboard
  version: "1.0.0"
  repository: "file://../dashboard"
```

## 5. Install Charts

To deploy a chart use the helm install command:
```bash
helm install --name <release_name> --namespace <my_namespace> --debug -f custom.yaml <chart_to_deploy>
```

- `--debug` prints out the deployment YAML to the terminal
- `--dry-run` w/ debug will print out the deployment YAML without actually deploying to OS/kubernetes env
- `--replace` will create new deployments if they are undefined or replace old ones if they exist
- `-f` allow you to pass in a file with values that can override the chart's defaults. (relative path)

For installing the entire Grey Matter service mesh, you can run this command:

```bash
helm install greymatter -f ./custom.yaml --name gm-deploy
```

## Extra Notes

### Deleting install:

To delete a deployment run `helm del --purge <namespace>`. This will delete everything in the deployment. If using OpenShift, you can use `oc get pods` and `oc get pvc` to check that the rescources in the deployment have been removed (persistent volumes seem to take longer than pods).

### Custom file:

You can override configurations in the `values.yaml` file by including them in the `custom.yaml` file, the `example-custom.yaml` file can be used to start modifications from. To use a custom file you will need to pass a flag, `-f <custom_file>`.

To override values in a particular chart's values.yaml file you will need to include a line in the custom.yaml file similar to the following:

```yaml
<chart_directory>
  <chart name>
      <key_to_override>: <value>
```

The most important keys for a barebones deployment are described in Step #2: Configuration above.

### Jenkins pipeline:

- To change the branch jenkins builds from use `./change-build-branch.sh`. The script will ask if you want to change to master, then your current branch, then a manual entry. You must be logged in openshift for this to work.

### Troubleshooting:

- Keep in mind that helm will not tear down any resources that it did not create in the firstplace. Therefore the best practice is to manage everything inside a project/namespace with helm or nothing at all.


### Additional Readme Files

Each subchart has a `README.md` which describes
 - details about the service
 - Helm configuration values
 - Helm tests/other testing options