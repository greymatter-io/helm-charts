#!/bin/sh

for cl in clusters/*.json
do
    key=$(jq .cluster_key $cl)
    key="${key%\"}"
    key="${key#\"}"
    greymatter delete cluster $key
done
for cl in domains/*.json
do
    key=$(jq .domain_key $cl)
    key="${key%\"}"
    key="${key#\"}"
    greymatter delete domain $key
done
for cl in listeners/*.json
do
    key=$(jq .listener_key $cl)
    key="${key%\"}"
    key="${key#\"}"
    greymatter delete listener $key
done
for cl in proxies/*.json
do
    key=$(jq .proxy_key $cl)
    key="${key%\"}"
    key="${key#\"}"
    greymatter delete proxy $key
done
for cl in rules/*.json
do
    key=$(jq .shared_rules_key $cl)
    key="${key%\"}"
    key="${key#\"}"
    greymatter delete shared_rules $key
done
for cl in routes/*.json
do
    key=$(jq .route_key $cl)
    key="${key%\"}"
    key="${key#\"}"
    greymatter delete route $key
done

curl -k -XDELETE --cert $GREYMATTER_API_SSLCERT --key $GREYMATTER_API_SSLKEY https://$GREYMATTER_API_HOST/services/catalog/latest/clusters/jwt-security?zoneName=zone-default-zone
