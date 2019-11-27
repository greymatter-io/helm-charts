#!/bin/bash

MINI='minikube'
LC=$(curl -s -m 2 169.254.169.254/latest/meta-data | wc -l )
if [ $LC -ge 4 ]; then
    MINI='sudo /home/ubuntu/bin/minikube' 
fi

echo "Grey Matter Dashboard is running at: https://$($MINI ip):30000"
