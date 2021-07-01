#!/bin/bash

if ! command -v acert &> /dev/null
then
    echo "acert could not be found"
    exit
fi

AUTH_FINGERPRINT=$(acert authorities create -n istio-quickstart)
acert authorities export $AUTH_FINGERPRINT -f pem -t authority > secrets/files/certs/global/ca.crt
acert authorities export $AUTH_FINGERPRINT -f pem -t certificate > secrets/files/certs/global/server.crt
acert authorities export $AUTH_FINGERPRINT -f pem -t key > secrets/files/certs/global/server.key
openssl pkcs12 -export -out cert.p12 -inkey secrets/files/certs/global/server.key -in secrets/files/certs/global/server.crt
security import cert.p12 -k ~/Library/Keychains/login.keychain-db