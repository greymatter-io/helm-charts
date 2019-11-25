#!/usr/bin/env bash


# remove edge configuration
greymatter delete cluster edge-data-standalone-cluster
greymatter delete shared_rules edge-data-standalone-shared-rules
greymatter delete route edge-data-standalone-route-slash
greymatter delete route sidecar-data-standalone-route-slash

# remove sidecar configuratiotn

greymatter delete cluster data-standalone-service
greymatter delete domain data-standalone
greymatter delete listener data-standalone-listener
greymatter delete proxy data-standalone-proxy
greymatter delete route data-standalone-route
greymatter delete shared_rules data-standalone-shared-rules

# remove special data-jwt configs
greymatter delete route data-standalone-jwt-route-slash
greymatter delete route data-standalone-jwt-route


echo "finish remove.sh"
