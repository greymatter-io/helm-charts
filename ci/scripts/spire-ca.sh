#!/bin/bash

addflg() {
    flags=$1
    flg=$2
    flgval=$3
    if ! [[ -z "$flgval" ]]; then
        n="$flg $flgval "
        flags+=$n
    fi
}

cacfg() {
    echo Enter the SPIRE release namespace, or press enter to use the default = \"spire\":
    read NS
    if [[ -z "$NS" ]]; then NS=spire; fi
    echo

    echo Enter the following to configure the authority, or press enter to use the default
    echo Common Name \(default Acert\):
    read CN; addflg "$flags" "-n" "$CN"
    echo Organization \(default Decipher Technology Studios\):
    read ORG; addflg "$flags" "-o" "$ORG"
    echo Country \(default US\):
    read CTRY; addflg "$flags" "-c" "$CTRY"
    echo State \(default Virginia\):
    read STATE; addflg "$flags" "-s" "$STATE"
    echo Locality \(default Alexandria\):
    read LOC; addflg "$flags" "-l" "$LOC"
    echo Organizational Unit \(default Engineering\):
    read ORGU; addflg "$flags" "-u" "$ORGU"
    echo Expiration Time \(default 87600h0m0s\):
    read EXP; addflg "$flags" "-e" "$EXP"
    echo Street Address \(default none\):
    read ADDR; addflg "$flags" "-a" "$ADDR"
    echo Postal Code \(default none\):
    read ZIP; addflg "$flags" "-p" "$ZIP"
}

flags=""

cd $(dirname "${BASH_SOURCE[0]}")
read -p "Do you wish to configure a custom upstream CA for SPIRE? [yn] " -n 1 yn
case $yn in
    [Yy]* ) 
        if ! command -v acert &> /dev/null 
        then 
            echo
            echo "*** acert must be installed to generate a custom upstream CA. Install here: https://github.com/deciphernow/acert#build ***" 
            exit 
        fi 
        echo -e "\nGenerating custom CA for SPIRE";
        cacfg $flags
        ;;
    [Nn]* ) echo -e "\nUsing Quickstart CA for SPIRE"; exit;;
    * ) echo -e "\nPlease answer yes or no. Defaulting to Quickstart CA"; exit;;
esac

cmd='acert authorities create '${flags}''
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

acert authorities delete ${AUTH_FINGERPRINT}

echo "SPIRE CA Updated, update global.spire.trust_domain and global.spire.namespace before installing"