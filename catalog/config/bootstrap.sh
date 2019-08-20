#!/usr/bin/env sh

MESH_CONFIG_DIR="/etc/config/mesh/"

echo "Configuring mesh from config directory: $MESH_CONFIG_DIR"

echo "Debug set to: $DEBUG"
if [ "$DEBUG" == "true" ]; then
    echo "DEBUG: Catalog API Host: $CATALOG_API_HOST"
fi

cd $MESH_CONFIG_DIR

echo "Config dir contains:"
ls

# This script expects the gm catalog api to be up and available to serve requests
# Currently, this is handled in a fairly good idiomatic way using Readiness Probes and `k8s-waiter`

echo "Starting catalog configuration ..."

delay=0.01

cd $MESH_CONFIG_DIR/zones
echo "Loading the zones to catalog ..."
for file in $(ls); do
    if [ "$DEBUG" == "true" ]; then
            echo "Contents of $file..."
            echo
            cat $file
            echo
            echo "Uploading $file..."
            curl -vv -X POST -d @$file  $CATALOG_API_HOST/zones
    else
        "Uploading $file..."
        curl -X POST -d @$file  $CATALOG_API_HOST/zones
    fi
done

cd $MESH_CONFIG_DIR/services
for d in */; do
    echo
    echo "Found service: $d"
    cd $d

    for file in $(ls); do
        echo "Creating catalog item $file"
        if [ "$DEBUG" == "true" ]; then
            echo "Contents of $d$file..."
            echo
            cat $file
            echo
            echo "Uploading $d$file..."
            curl -vv -X POST -d @$file  $CATALOG_API_HOST/clusters
        else
            curl -X POST -d @$file  $CATALOG_API_HOST/clusters
        fi
    done

    cd $MESH_CONFIG_DIR/services
done

echo "Catalog configuration complete"
