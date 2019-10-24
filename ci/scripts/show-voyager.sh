#!/bin/bash
minikube -p gm-deploy service list | grep voyager | head -n 1 | sed 's/http/https/' | awk '{print "Grey Matter dashboard is running at:", $6}'
