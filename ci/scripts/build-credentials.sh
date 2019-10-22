#!/bin/bash
cd $(dirname "${BASH_SOURCE[0]}")
echo decipher email: 
read EMAIL
echo password:
read PASSWORD
export EMAIL
export PASSWORD
envsubst < credentials.template > ../../credentials.yaml
