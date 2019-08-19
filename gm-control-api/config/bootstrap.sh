#!/usr/bin/env sh

MESH_CONFIG_DIR="/etc/config/mesh/"

echo "Configuring mesh from config directory: $MESH_CONFIG_DIR"

cd $MESH_CONFIG_DIR

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

# The edge service is created last as it links to the clusters of every other service.
# The edge domain must be created before it can be referenced
cd $MESH_CONFIG_DIR/special
echo "Creating special configuration objects (domain, edge listener + proxy)"
greymatter create domain < domain.json
greymatter create listener <listener.json
greymatter create proxy < proxy.json
greymatter create cluster < cluster.json
greymatter create shared_rules < shared_rules.json
greymatter create route < route.json

# for file in $(ls route*.json); do 
#     greymatter create route < $file
# done

cd $MESH_CONFIG_DIR/edge
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

    cd $MESH_CONFIG_DIR/edge
done

cd $MESH_CONFIG_DIR/special
echo "Adding additional Special Routes"
for rte in $(ls route-*.json); do
    greymatter create route < $rte
done
# greymatter create route < route-data-jwt-slash.json
# greymatter create route < route-data-jwt.json
# greymatter create route < route-dashboard-slash.json