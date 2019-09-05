#!/usr/bin/env sh

set -eo pipefail

MESH_CONFIG_DIR="/etc/config/mesh/"
CURL_COMMAND='curl -s -o /dev/null -w "%{http_code}"'
HTTP="http"

echo "Configuring mesh from config directory: $MESH_CONFIG_DIR"

echo "Debug set to: $DEBUG"
if [ "$DEBUG" == "true" ]; then
    set -x
    echo "DEBUG: Catalog API Host: $CATALOG_API_HOST"
    echo "DEBUG: Catalog API USE_TLS: $USE_TLS "
fi

cd $MESH_CONFIG_DIR

if [ "$USE_TLS" == "true" ]; then
    CURL_COMMAND='curl -s -o /dev/null -w "%{http_code}" -k --cacert /etc/pki/ca.crt --cert /etc/pki/server.crt --key /etc/pki/server.key'
    HTTP="https"
fi

echo "Config dir contains:"
ls

# This script expects the gm catalog api to be up and available to serve requests
# Currently, this is handled in a fairly good idiomatic way using Readiness Probes and `k8s-waiter`

echo "Starting catalog configuration ..."

delay=0.01

sendCommand() {
    if [ "$DEBUG" == "true" ]; then
        echo "Contents of $2..."
        echo
        cat $2
        echo
    fi

    echo "Uploading $file..."
    http_response=$($CURL_COMMAND -X POST -d @$2 $HTTP://$CATALOG_API_HOST/$1)
    if [ "$DEBUG" == "true" ]; then
        echo $http_response
    fi 

    http_response="${http_response%\"}"
    http_response="${http_response#\"}"

    if [ $http_response != "200" ]; then
        echo "There was an error uploading a file to catalog.  Exiting"
        exit 1
    fi
    
}

cd $MESH_CONFIG_DIR/zones
echo "Loading the zones to catalog ..."
for file in $(ls); do
    sendCommand zones $file
done

cd $MESH_CONFIG_DIR/services
for d in */; do
    echo
    echo "Found service: $d"
    cd $d

    for file in $(ls); do
        echo "Creating catalog item $file"
        sendCommand clusters $file
    done

    cd $MESH_CONFIG_DIR/services
done

echo "Catalog configuration complete"
