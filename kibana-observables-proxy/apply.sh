#!/bin/sh

for cl in clusters/*.json; do greymatter create cluster < $cl; done
for cl in domains/*.json; do greymatter create domain < $cl; done
for cl in listeners/*.json; do greymatter create listener < $cl; done
for cl in proxies/*.json; do greymatter create proxy < $cl; done
for cl in rules/*.json; do greymatter create shared_rules < $cl; done
for cl in routes/*.json; do greymatter create route < $cl; done

curl -k -XPOST --cert $GREYMATTER_API_SSLCERT --key $GREYMATTER_API_SSLKEY https://$GREYMATTER_API_HOST/services/catalog/latest/clusters -d "@catalog/catalog.json"
