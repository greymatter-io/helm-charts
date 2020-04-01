# Deploying with SPIRE in Minikube

Use the following steps to deploy the Grey Matter helm charts using minikube with SPIRE enabled.

This largely follows the [Deploy with Minikube](../Deploy%20with%20Minikube.md) documentation.

1. Start Minikube.

    ```bash
    minikube start -p gm-deploy --memory 26384 --cpus 6 \
        --extra-config=apiserver.service-account-signing-key-file=/var/lib/minikube/certs/sa.key \
        --extra-config=apiserver.service-account-key-file=/var/lib/minikube/certs/sa.pub \
        --extra-config=apiserver.service-account-issuer=api \
        --extra-config=apiserver.service-account-api-audiences=api,spire-server \
        --extra-config=apiserver.authorization-mode=Node,RBAC \
        --extra-config=kubelet.authentication-token-webhook=true
    ```

2. Install secrets, and the spire server.

    ```bash
    make credentials

    helm dep up secrets
    helm install secrets secrets -f credentials.yaml

    helm dep up spire
    helm install server spire/server
    ```

    When the server is `2/2` in `kubectl get pods -n spire`, start up the agent:

    ```bash
    helm install agent spire/agent
    ```


3. Make sure the Grey Matter `<chart>/values.yaml` files properly configure spire. First, enable spire as below, and make sure the value in `trust_domain` matches the `.Values.global.spire.trust_domain` passed to the spire chart.

    ```yaml
    global:
    # Whether or not to use spire for cert management and the trust domain
    spire:
        enabled: true
        trust_domain: quickstart.greymatter.io
    ```

    All other configuration requirements are noted in the `<chart>/values.yaml` files with `# SPIRE:`. **Make sure to make the changes as noted in these comments before installing each chart**.

4. Once all chart values files are properly configured for spire, install the charts as usual (the below uses kubernetes and edge voyager ingress):

    ```bash
    helm repo add appscode https://charts.appscode.com/stable/
    helm repo update
    helm install voyager-operator appscode/voyager \
    --version v12.0.0-rc.0   \
    --namespace kube-system   \
    --set cloudProvider=minikube

    helm dep up fabric
    helm install fabric fabric --set=global.environment=kubernetes

    helm dep up edge
    helm install edge edge --set=global.environment=kubernetes

    helm dep up data
    helm install data data --set=global.environment=kubernetes --set=global.waiter.service_account.create=false

    helm dep up sense
    helm install sense sense --set=global.environment=kubernetes --set=global.waiter.service_account.create=false
    ```

5. You should see all pods come up and should be able to access the dashboard by running:

    ```bash
    minikube -p gm-deploy service --https=true voyager-edge
    ```

To take a look at the specific spire configuration and troubleshooting, see the [configuration docs](./configuration.md).
