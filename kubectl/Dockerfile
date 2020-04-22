FROM bitnami/kubectl:latest
ADD --chown=1001:1001 kubeconfig ./.kube/config

ARG HELM_VERSION=v3.1.1
ENV HELM_HOME=/usr/local/helm

RUN apt -v update install \
    ca-certificates \
    bash \
    curl

USER root

RUN wget -q https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz -O - | tar -xzO linux-amd64/helm > /usr/local/bin/helm && \
    chmod +x /usr/local/bin/helm
