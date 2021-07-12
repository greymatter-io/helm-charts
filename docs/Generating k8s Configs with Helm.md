# Generating k8s Configuration with Helm

## Configuring the Deployment

If you know all the custom values necessary to generate the deployment ahead of time, place them in a `custom.yaml` file to pass into your `helm template` command.

## Templating

The most straightforward way to generate a templated configuration is to clone the [Decipher Helm charts repository](https://github.com/DecipherNow/helm-charts) and run the the following command:

```sh
helm dep up <chart>
helm template <release-name> <chart> -f custom > template.yaml
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
