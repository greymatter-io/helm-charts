#!/usr/bin/env sh

set -eo pipefail

CONFIG_DIR="/etc/config/mesh"
CURL_COMMAND='curl -s -o /dev/null -w "%{http_code}"'
HTTP="http"

create_or_update() {
  kind=$1
  filename=$2
  mesh_id=$3
  service_id=$4

  if [ "$DEBUG" == "true" ]; then
    echo "DEBUG: Contents of $kind in $filename..."
    echo
    cat $filename
    echo
    echo
  fi

  if [ $kind == "mesh" ]; then
    echo "Checking for existing mesh $mesh_id..."
    http_response=$(${CURL_COMMAND} -X GET $HTTP://$CATALOG_API_HOST/meshes/$mesh_id)
    http_response="${http_response%\"}"
    http_response="${http_response#\"}"

    if [ $http_response == "404" ]; then
      echo "Not found; creating $mesh_id from $filename..."
      http_response=$(${CURL_COMMAND} -X POST -d @$filename $HTTP://$CATALOG_API_HOST/meshes)
      http_response="${http_response%\"}"
      http_response="${http_response#\"}"

      if [ "$http_response" != "200" ]; then
        echo "Failed to create mesh $mesh_id. Exiting."
        exit 1
      else
        echo "Created mesh $mesh_id!"
      fi
    else
      echo "Already exists."
    fi

  elif [ $kind == "service" ]; then
    echo "Checking for existing service $service_id in mesh $mesh_id..."
    http_response=$(${CURL_COMMAND} -X GET $HTTP://$CATALOG_API_HOST/meshes/$mesh_id/services/$service_id)
    http_response="${http_response%\"}"
    http_response="${http_response#\"}"

    if [ $http_response == "404" ]; then
      echo "Not found; creating service $service_id in mesh $mesh_id from $filename..."
      http_response=$(${CURL_COMMAND} -X POST -d @$filename $HTTP://$CATALOG_API_HOST/services)
      http_response="${http_response%\"}"
      http_response="${http_response#\"}"

      if [ "$http_response" != "200" ]; then
        echo "Failed to create service $service_id in mesh $mesh_id. Exiting."
        exit 1
      else
        echo "Created service $service_id in mesh $mesh_id!"
      fi
    else
      echo "Already exists."
    fi
  fi
}

echo "Configuring from directory $CONFIG_DIR"

if [ "$DEBUG" == "true" ]; then
  set -x
    echo "DEBUG: Catalog API Host: $CATALOG_API_HOST"
    echo "DEBUG: Catalog API USE_TLS: $USE_TLS"
fi

if [ "$USE_TLS" == "true" ]; then
  HTTP="https"
	CURL_COMMAND='curl -s -o /dev/null -w "%{http_code}" -k --cacert '"$CERTS_MOUNT"'/'"$CA_CERT"' --cert '$CERTS_MOUNT'/'$CERT' --key '$CERTS_MOUNT'/'$KEY
fi

# This script expects the Catalog API to be up and available to serve requests
# Currently, this is handled in a fairly good idiomatic way using readiness probes and `k8s-waiter`

delay=0.01

cd $CONFIG_DIR/meshes
meshes=$(ls)

echo "Loading meshes into Catalog..."

for filename in $meshes; do
  create_or_update mesh $filename ${filename%.json}
done

cd $CONFIG_DIR/services

echo "Loading services into Catalog..."

for d in */; do
  cd $CONFIG_DIR/services/$d
  for filename in $(ls); do
    for mesh in $meshes; do
      create_or_update service $filename ${mesh%.json} ${d%/}
    done
  done
done
