#!/bin/bash
minikube -p gm-deploy service list | grep voyager | head -n 1 | sed 's/http/https/' | awk '{print $4} {print $6}'
