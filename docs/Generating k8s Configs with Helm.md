# Generating k8s Configuration with Helm

It is sometimes necessary to deploy Grey Matter without the use of Tiller, Helm's server side component. Luckily, Helm provides commands that can be used to generate raw Kubernetes (k8s) configuration.

To generate configuration, you will still need to install Tiller into a Kubernetes cluster in order to run commands. The easiest way to do this is locally using [Minikube.](./Deploy%20with%20Minikube.md) This guide assumes that you have [Tiller installed](./Deploy%20with%20Minikube.md#Setup%20Helm) and have added the Decipher [Helm repository](./Deploy%20with%20Minikube.md#Latest%20Helm%20charts%20release).

## Configuring the Deployment

If you know all the custom values necessary to generate the deployment ahead of time, fill out `greymatter.yaml` and `greymatter-secrets.yaml` which are hosted in the [Decipher Helm charts repo](https://github.com/DecipherNow/helm-charts) and [run the template command](#templating) with them.

If deployment configuration is not known beforehand, for example if the template is being passed off to a customer, you can just add placeholder values to `greymatter.yaml`.

## Templating

The most straightforward way to generate configuration is to clone the [Decipher Helm charts repository](https://github.com/DecipherNow/helm-charts) and run the the following command:

```sh
helm template greymatter -f greymatter.yaml -f greymatter-secrets.yaml > template.yaml
```

The template command can also be run on charts hosted in remote repositories, albeit not directly. To get around that, first fetch and untar the remote charts before running the template command:

```sh
helm fetch --untar --untardir . decipher/greymatter
helm template greymatter -f greymatter.yaml -f greymatter-secrets.yaml > template.yaml
```

## Deploying

To validate `template.yaml` and confirm that placeholders were templated correctly, run the following:

```sh
kubectl apply -f template.yaml --dry-run=true --validate=true
```

If this was successful, apply the file:

```sh
kubectl apply -f template.yaml
```
