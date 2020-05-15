#!/bin/bash

IP="Not Found"

LC=$(curl -s -m 2 169.254.169.254/latest/meta-data | wc -l )
if [ $LC -ge 4 ]; then
    IP=$(curl -s 169.254.169.254/latest/meta-data/public-ipv4)
elif [ hash minikube 2>/dev/null ]; then
    IP=$(minikube ip)
else
    IP=localhost
fi

echo "Grey Matter Dashboard is running at: https://$IP:30000"
