#!/usr/bin/env bash
# set -e

# remove edge configuration
greymatter delete cluster edge-REPLACESTRING-cluster
greymatter delete shared_rules edge-REPLACESTRING-shared-rules
greymatter delete route edge-REPLACESTRING-route-slash
greymatter delete route sidecar-REPLACESTRING-route-slash

# remove sidecar configuratiotn

greymatter delete cluster REPLACESTRING-service
greymatter delete domain REPLACESTRING
greymatter delete listener REPLACESTRING-listener
greymatter delete proxy REPLACESTRING-proxy
greymatter delete route REPLACESTRING-route
greymatter delete shared_rules REPLACESTRING-shared-rules

# remove special data-jwt configs
greymatter delete route REPLACESTRING-jwt-route-slash
greymatter delete route REPLACESTRING-jwt-route

echo "finish remove.sh"
