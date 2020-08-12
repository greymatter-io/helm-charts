#!/bin/bash

cacfg() {
    echo Enter the SPIRE release namespace, or press enter to use the default = \"spire\":
    read NS
    if [[ -z "$NS" ]]; then NS=spire; fi
    echo

    echo Enter the following to configure the authority, or press enter to use the default
    echo Common Name \(default Acert\):
    read N; if [[ -z "$N" ]]; then N=Acert; fi
    echo Organization \(default Decipher Technology Studios\):
    read O; if [[ -z "$O" ]]; then O='Decipher Technology Studios'; fi
    echo Country \(default US\):
    read C; if [[ -z "$C" ]]; then C=US; fi
    echo State \(default Virginia\):
    read S; if [[ -z "$S" ]]; then S=Virginia; fi
    echo Locality \(default Alexandria\):
    read L; if [[ -z "$L" ]]; then L=Alexandria; fi
    echo Organizational Unit \(default Engineering\):
    read U; if [[ -z "$U" ]]; then U=Engineering; fi
    echo Expiration Time \(default 87600h0m0s\):
    read E; if [[ -z "$E" ]]; then E=87600h0m0s; fi
    echo Street Address \(default none\):
    read A;
    echo Postal Code \(default none\):
    read P;
}

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
        cacfg
        ;;
    [Nn]* ) echo -e "\nUsing Quickstart CA for SPIRE"; exit;;
    * ) echo -e "\nPlease answer yes or no. Defaulting to Quickstart CA"; exit;;
esac

AUTH_FINGERPRINT=$(acert authorities create -n "$N" -o "$O" -c "$C" -s "$S" -l "$L" -u "$U" -e "$E" -a "$A" -p "$P")

kubectl create secret generic server-ca \
  -n $NS \
  -o yaml \
  --dry-run=client \
  --from-literal=root.crt="$(acert authorities export $AUTH_FINGERPRINT -t authority -f pem)" \
  --from-literal=intermediate.crt="$(acert authorities export $AUTH_FINGERPRINT -t certificate -f pem)" \
  --from-literal=intermediate.key="$(acert authorities export $AUTH_FINGERPRINT -t key -f pem)" > \
  ../../spire/server/templates/server-ca-secret.yaml

REGISTRAR_FINGERPRINT=$(acert authorities issue $AUTH_FINGERPRINT -n 'registrar.'$NS'.svc')

kubectl create secret generic server-tls \
  -n $NS \
  -o yaml \
  --dry-run=client \
  --from-literal=ca.crt="$(acert leaves export $REGISTRAR_FINGERPRINT -t authority -f pem)" \
  --from-literal=registrar.${NS}.svc.crt="$(acert leaves export $REGISTRAR_FINGERPRINT -t certificate -f pem)" \
  --from-literal=registrar.${NS}.svc.key="$(acert leaves export $REGISTRAR_FINGERPRINT -t key -f pem)" > \
  ../../spire/server/templates/server-tls-secret.yaml

CABUNDLE="$(acert leaves export $REGISTRAR_FINGERPRINT -t authority -f pem | base64)"

sed -i "" "s/caBundle: .*/caBundle: $CABUNDLE/" ../../spire/server/templates/validatingwebhookconfiguration.yaml

acert authorities delete ${AUTH_FINGERPRINT}

echo "SPIRE CA Updated"
if ! [[ $NS == "spire" ]];
then
    echo "Set global.spire.namespace=${NS} and optionally update global.spire.trust_domain"
else
    echo "Optionally update global.spire.trust_domain"
fi