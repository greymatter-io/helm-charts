#!/usr/bin/env bash
set -e

# edge configuration

echo "Define cluster for a sidecars service"
greymatter create cluster < edge/data-standalone-cluster.json

echo "Define rule for directing traffic to service cluster"
greymatter create shared_rules < edge/data-standalone-shared_rules.json

echo "Add route from sidecar to service cluster"
greymatter create route < edge/data-standalone-route-1.json

echo "Add route 2 from edge to sidecar (with trailing slash)"
greymatter create route < edge/data-standalone-route-2.json


# sidecar configuration

echo "Define cluster for sidecar's discovered instances"
greymatter create cluster < sidecar/cluster.json

echo "Define domain for sidecar route to its service"
greymatter create domain < sidecar/domain.json

echo "Define listener for downstream requests to sidecar"
greymatter create listener < sidecar/listener.json

echo "Define proxy"
greymatter create proxy < sidecar/proxy.json

echo "Define rule for directing traffic to sidecar cluster"
greymatter create shared_rules < sidecar/shared_rules.json

echo "Add route 1 from edge to sidecar (no trailing slash)"
greymatter create route < sidecar/route.json


# special configuration

greymatter create route < special/route-data-standalone-jwt-slash.json
greymatter create route < special/route-data-standalone-jwt.json


echo "finish populate.sh"
