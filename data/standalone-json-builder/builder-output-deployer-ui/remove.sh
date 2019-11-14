#!/usr/bin/env bash
# set -e

# remove edge configuration
greymatter delete cluster edge-deployer-ui-cluster
greymatter delete shared_rules edge-deployer-ui-shared-rules
greymatter delete route edge-deployer-ui-route-slash
greymatter delete route sidecar-deployer-ui-route-slash

# remove sidecar configuratiotn

greymatter delete cluster deployer-ui-service
greymatter delete domain deployer-ui
greymatter delete listener deployer-ui-listener
greymatter delete proxy deployer-ui-proxy
greymatter delete route deployer-ui-route
greymatter delete shared_rules deployer-ui-shared-rules

# remove special data-jwt configs
greymatter delete route deployer-ui-jwt-route-slash
greymatter delete route deployer-ui-jwt-route

echo "finish remove.sh"
