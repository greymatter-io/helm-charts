#!/bin/sh

set -ex


original=$(pwd)/configs/edge_listener.json
templated="${original}-templated"
> $templated

# edge domain
export DOMAIN=$(kubectl get svc edge -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
# keycloak http
export PROVIDER="http://$(kubectl get svc keycloak-backend -o jsonpath="{.status.loadBalancer.ingress[*].hostname}"):80/auth/realms/greymatter"
# full edge URL
export SERVICE_URL="https://$(kubectl get svc edge -o jsonpath="{.status.loadBalancer.ingress[*].hostname}"):10808"
envsubst < $original >> $templated

greymatter edit listener edge-listener < $templated

echo "Add to Valid Redirect URIs: $SERVICE_URL/oauth"
