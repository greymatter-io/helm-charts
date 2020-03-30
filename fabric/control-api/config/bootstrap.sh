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

# Create or update takes an object type and an optional filename
create_or_update() {
    file=$2
    # If file is null, set to objecttype.json, eg route.json
    if [ -z "$file" ]; then
        file=$1.json
    fi

    echo "Creating object with $file"
    resp=$(greymatter create $1 <$file)
    echo "$resp"
    # If response from the api is null, try editing the object
    if [ -z "$resp" ]; then
        echo "Object already exists! Editing $file"
        greymatter edit $1 _ <$file
    fi

    echo "----------"
}

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
        if [ "$name" == "domain" ]; then
            create_or_update $name domain-egress.json
        elif [ "$name" == "listener" ]; then
            create_or_update $name listener-egress.json
        fi
        create_or_update $name
        sleep $delay
    done

    cd $MESH_CONFIG_DIR/services
done

# The edge service is created last as it links to the clusters of every other service.
# The edge domain must be created before it can be referenced
cd $MESH_CONFIG_DIR/special
echo "Creating special configuration objects (domain, edge listener + proxy)"
create_or_update "domain"
create_or_update "domain" domain-egress.json
create_or_update "listener"
create_or_update "listener" listener-egress.json
create_or_update "proxy"
create_or_update "cluster"
create_or_update "shared_rules"
create_or_update "route"

cd $MESH_CONFIG_DIR/edge
echo "Creating edge configuration objects"

# All the following services reference the `edge` domain key
for d in */; do
    echo "Found service: $d"
    cd $d

    names="cluster shared_rules"
    for name in $names; do
        echo "Creating mesh object: $name."
        create_or_update $name
        sleep $delay
    done

    for file in route-*.json; do
        echo "Creating mesh object: $name."
        create_or_update "route" $file
        sleep $delay
    done

    cd $MESH_CONFIG_DIR/edge
done

cd $MESH_CONFIG_DIR/services
# After all service + edge objects have been created, we need to add egress jwt routes to each service proxy
# This is done in another loop because it references internal-jwt & edge keys
for d in */; do
    echo "Found service: $d"
    cd $d

    # Create JWT egress routes for each proxy
    create_or_update route route-jwt-slash.json
    create_or_update route route-jwt.json

    cd $MESH_CONFIG_DIR/services
done

cd $MESH_CONFIG_DIR/special
echo "Adding additional Special Routes"
for rte in $(ls route-*.json); do
    create_or_update "route" $rte
done

# greymatter create route < route-data-jwt-slash.json
# greymatter create route < route-data-jwt.json
# greymatter create route < route-dashboard-slash.json
