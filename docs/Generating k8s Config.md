# Generating k8s Configuration with Helm

It is sometimes necessary to deploy Grey Matter without the use of Helm/Tiller. Luckily, Helm provides commands that can be used to generate raw kubernetes configuration.

## Configuring the deployment

If you know all the custom values necessary to generate the deployment ahead of time, fill out `greymatter.yaml` and `greymatter-secrets.yaml` which are hosted in the [Decipher Helm charts repo](https://github.com/DecipherNow/helm-charts) and [run the template command](#generating-templated-k8s-config) with them.

If deployment configuration is not known beforehand, for example if the template is being passed off to a client, you can just add placeholder values to `greymatter.yaml`.

## Templating

The most straightforward way to generate configuration is to clone the [Decipher Helm charts repository](https://github.com/DecipherNow/helm-charts) and run the the following command:

```sh
helm template greymatter -f greymatter.yaml -f greymatter-secrets.yaml
```

The template command can also be run on charts hosted in remote repositories, albeit not directly. To get around that, first fetch and untar the remote charts before running the templating command:

```sh
helm fetch --untar --untardir . decipher/greymatter
helm template greymatter -f greymatter.yaml -f greymatter-secrets.yaml
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

## Authors

- Kaitlin Moreno - kaitlin.moreno@deciphernow.com
