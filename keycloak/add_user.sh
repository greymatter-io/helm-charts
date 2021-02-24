#!/bin/bash

set -ex pipefail

endpoint="https://a85482a33bd744aef8f46295cbc1d589-753440034.us-east-1.elb.amazonaws.com"
token=$(curl -k --location --request POST \
--header 'Content-Type: application/x-www-form-urlencoded' \
--data-urlencode 'grant_type=client_credentials' \
--data-urlencode 'client_id=admin-cli' \
--data-urlencode "client_secret=$CLIENT_SECRET" \
 "$endpoint/auth/realms/greymatter/protocol/openid-connect/token" \
| jq -r ".access_token")



# docs: https://www.keycloak.org/docs-api/9.0/rest-api/index.html#_users_resource
path="$(pwd)/temp"
for f in "$path/*.json"; do
	data=$(cat $f)
	echo $data
	curl -k --location --request POST \
	--header 'Content-Type: application/json' \
	--header "Authorization: Bearer $token" \
	--data-raw "$data" \
	 "$endpoint/auth/admin/realms/greymatter/users"
done

