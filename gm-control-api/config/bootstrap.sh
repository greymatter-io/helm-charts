#!/usr/bin/env sh

MESH_CONFIG_DIR="/etc/config/mesh/"

echo "Configuring mesh from config directory: $MESH_CONFIG_DIR"

cd $MESH_CONFIG_DIR

greymatter version

echo "Config dir contains:"
ls

# This script expects gm-control-api to be up and available to serve requests
# Currently, this is handled in a fairly good idiomatic way using Readiness Probes and `k8s-waiter`

echo "Starting mesh configuration ..."

echo "Creating service configuration objects..."

delay=0.01

cd $MESH_CONFIG_DIR/services
# Each service should be able to be created all by itself. This means it needs to contain a domain
for d in */; do
    echo "Found service: $d"
    cd $d

    # The ordering of creating gm-control-api resources is extremely important and precise.
    # All objects referenced by keys must be created before being referenced or will result in an error.
    # So we add a delay of 0.1 seconds between each request to hopefully streamline this
    # A better option is probably to hardcode the order of items

    names="domain cluster listener proxy shared_rules route"
    for name in $names; do
        echo "Creating mesh object: $name."
        greymatter create $name <$name.json
        sleep $delay
    done

    cd $MESH_CONFIG_DIR/services
done

# There are two possible edge services - edge and edge-oauth. There will always be at least one edge.
# If a user chooses to enable edge-oauth, the normal edge service will be used for one thing - external ingress
# into the control plane. The control-api service will reference both edge and edge-oauth, while the remainder
# only reference edge-oauth.

# The edge services are created last as they link to the clusters of every other service.
# The edge services domains must be created before they can be referenced.

OAUTH_ENABLED=false
if [ -d "/etc/config/mesh/services/edgeOAuth" ]; then
    OAUTH_ENABLED=true
    cd $MESH_CONFIG_DIR/special/edge-oauth
    echo "Creating edge-oauth special configuration objects (domain, edge listener + proxy)"
    greymatter create domain <domain.json
    greymatter create listener <listener.json
    greymatter create proxy <proxy.json
    greymatter create cluster <cluster.json
    greymatter create shared_rules <shared_rules.json
    greymatter create route <route.json
fi

# We always create an edge service.
cd $MESH_CONFIG_DIR/special/edge
echo "Creating edge special configuration objects (domain, edge listener + proxy)"
greymatter create domain <domain.json
greymatter create listener <listener.json
greymatter create proxy <proxy.json
greymatter create cluster <cluster.json
greymatter create shared_rules <shared_rules.json
greymatter create route <route.json

EDGE_CONFIG_DIR=$MESH_CONFIG_DIR/edge
if [ $OAUTH_ENABLED  ]; then
    EDGE_CONFIG_DIR=$MESH_CONFIG_DIR/edge-oauth

    # In the case of edge-oauth, the only service accessible from the other edge is control-api.
    cd $MESH_CONFIG_DIR/edge
    if [ "/etc/config/mesh/services/controlApi" ]; then
        cd "/etc/config/mesh/services/controlApi"
        greymatter create cluster <cluster.json
        greymatter create shared_rules <shared_rules.json
        greymatter create route-1 <route-1.json
        greymatter create route-2 <route-2.json
    fi
fi

cd $EDGE_CONFIG_DIR
echo "Creating edge configuration objects"

# All the following services reference the `edge` domain key
for d in */; do
    echo "Found service: $d"
    cd $d

    names="cluster shared_rules"
    for name in $names; do
        echo "Creating mesh object: $name."
        greymatter create $name <$name.json
        sleep $delay
    done

    for file in route-*.json; do
        echo "Creating mesh object: $name."
        greymatter create route <$file
        sleep $delay
    done

    cd $EDGE_CONFIG_DIR
done

cd $MESH_CONFIG_DIR/special
echo "Adding additional Special Routes"
for rte in $(ls route-*.json); do
    greymatter create route <$rte
done
