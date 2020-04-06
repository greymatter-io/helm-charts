# SPIRE

## Deploying with SPIRE on minikube

To deploy Grey Matter using SPIRE on minikube, make sure the required versions as stated in [Deploy with Minikube docs](../docs/Deploy%20with%20Minikube.md#prerequisites) are installed. Follow the documentation there but start minikube with the following command:

```bash
minikube start -p gm-deploy --memory 26384 --cpus 6 \
    --extra-config=apiserver.service-account-signing-key-file=/var/lib/minikube/certs/sa.key \
    --extra-config=apiserver.service-account-key-file=/var/lib/minikube/certs/sa.pub \
    --extra-config=apiserver.service-account-issuer=api \
    --extra-config=apiserver.service-account-api-audiences=api,spire-server \
    --extra-config=apiserver.authorization-mode=Node,RBAC \
    --extra-config=kubelet.authentication-token-webhook=true
```

## Makefile

| command        | description                         | comments |
| -------------- | ----------------------------------- | -------- |
| server         | install standalone spire server     |          |
| agent          | install standalone spire agent      |          |
| clean-spire    | remove charts/*                     |          |
| package-spire  | package spire                       |          |
| template-spire | template spire with values          |          |
| spire          | package and install spire component |          |
| remove-spire   | uninstalls spire component          |          |
