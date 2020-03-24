# Secrets

## Populate credentials.yaml

run `make credentials` to build your `credentials.yaml` file which is used for the image pull secret

## Makefile

| command        | description                 | comments                         |
| -------------- | --------------------------- | -------------------------------- |
| credentials    | `creates credentials.yaml`  |                                  |
| secrets        | populates secrets component | Create base secrets used by mesh |
| remove-secrets | uninstall secrets component |                                  |
