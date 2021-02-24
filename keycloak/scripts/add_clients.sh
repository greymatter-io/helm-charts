#!/bin/sh

set -ex pipefail

endpoint="https://$(kubectl get svc keycloak-backend -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")"
username="user"
password=$(kubectl get secret --namespace default keycloak-backend -o jsonpath="{.data.admin-password}" | base64 --decode)

access_token=$(curl -k\
	--data "username=$username&password=$password&grant_type=password&client_id=admin-cli" \
	$endpoint/auth/realms/master/protocol/openid-connect/token \
	| jq -r ".access_token")


# create realm 
# docs: https://www.keycloak.org/docs-api/5.0/rest-api/index.html#_realms_admin_resource
path="$(pwd)/realms"
curl -k --location --request POST \
--header 'Content-Type: application/json' \
--header "Authorization: Bearer $access_token" \
--data-raw "$data" \
 "$endpoint/auth/" | jq 
