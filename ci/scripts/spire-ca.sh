#!/bin/bash

cd $(dirname "${BASH_SOURCE[0]}")
read -p "Do you wish to configure a custom upstream CA for SPIRE? [yn] " -n 1 yn
case $yn in
    [Yy]* ) echo -e "\nGenerating custom CA for SPIRE";;
    [Nn]* )
        echo -e "\nUsing Quickstart CA for SPIRE"
        exit
        ;;
    * )
        echo -e "\nPlease answer yes or no. Defaulting to Quickstart CA"
        exit
        ;;
esac

echo Common Name:
read CN
echo Organization:
read ORG
echo Spire Release Namespace:
read NS

cmd='acert authorities create -n '${CN}' -o '${ORG}''
AUTH_FINGERPRINT=$($cmd)

kubectl create secret generic server-ca \
  -n $NS \
  -o yaml \
  --dry-run=client \
  --from-literal=root.crt="$(acert authorities export ${AUTH_FINGERPRINT} -t authority -f pem)" \
  --from-literal=intermediate.crt="$(acert authorities export ${AUTH_FINGERPRINT} -t certificate -f pem)" \
  --from-literal=intermediate.key="$(acert authorities export ${AUTH_FINGERPRINT} -t key -f pem)" > \
  ../../spire/server/templates/server-ca-secret.yaml

REGISTRAR_FINGERPRINT=$(acert authorities issue ${AUTH_FINGERPRINT} -n 'registrar.'${NS}'.svc')

kubectl create secret generic server-tls \
  -n $NS \
  -o yaml \
  --dry-run=client \
  --from-literal=ca.crt="$(acert leaves export ${REGISTRAR_FINGERPRINT} -t authority -f pem)" \
  --from-literal=registrar.${NS}.svc.crt="$(acert leaves export ${REGISTRAR_FINGERPRINT} -t certificate -f pem)" \
  --from-literal=registrar.${NS}.svc.key="$(acert leaves export ${REGISTRAR_FINGERPRINT} -t key -f pem)" > \
  ../../spire/server/templates/server-tls-secret.yaml

CABUNDLE="$(acert leaves export ${REGISTRAR_FINGERPRINT} -t authority -f pem | base64)"

sed -i "" "s/caBundle: .*/caBundle: $CABUNDLE/" ../../spire/server/templates/validatingwebhookconfiguration.yaml

echo "CA Updated, update global.spire.trust_domain and global.spire.namespace before installing"