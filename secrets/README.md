# Secrets

## TLDR

- Edit `values.yaml` and `global.yaml` files
- Add credential and secrets to values file and/or into the appropriate directory in `files/`
- Run `make credentials.yaml`
- Run `make secrets` to add secrets to mesh
- Run `kubectl get secrets` to verify secrets are in place

## Populate credentials.yaml

Run `make credentials` to build your `credentials.yaml` file which is used for the image pull secret

## Makefile

| command        | description                 | comments                         |
| -------------- | --------------------------- | -------------------------------- |
| credentials    | `creates credentials.yaml`  |                                  |
| secrets        | populates secrets component | Create base secrets used by mesh |
| remove-secrets | uninstall secrets component |                                  |

## Docker Secret

The docker-secret.yaml template can accept multiple repository entries if you will be pulling from multiple locations.  This is particularly helpful during the development process when pulling from dev and prod repositories.

### Example

```yaml
dockerCredentials:
  - registry: docker.repo1
    email: user@email.com
    username: user@email.com
    password: p@ssWord1
  - registry: docker.repo2
    email: user@email.com
    username: user@email.com
    password: p@ssWord2
```

## Certificates and Secrets

### Global Certificates

Enable global certificates by setting `global.global_certs.enabled=true` in the `global.yaml` file.  This will simplify the deployment by using one set of certificates for many of the services. (certificates can be defined in global.yaml or pulled from a file)

### From values.yaml

Secrets and certificates may be defined in the values file.  These values will be sourced during `make secrets` to create the Kubernetes secrets.

### From File

All certificates (and jwt secrets) can be defined either by an entry in the values file or by placing a file in the appropriate subdirectory of `./files/`.  The default is to use values defined in the `values.yaml` file.  However if `from_file.enabled=true` and `from_file.path` specifies a path to desired files then the those files will be sourced for the secret during `make secrets`.  *Note: this is done per certificate so each service will need these two values specified*.

```yaml
from_file:
  enabled: true
  path: files/certs/ingress
```
