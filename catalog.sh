#!/usr/bin/env bash

curl -X PUT localhost:9080/meshes/istio-demo -d '{
  "mesh_id": "istio-demo",
  "mesh_type": "istio",
  "name": "Istio Mesh",
  "sessions": {
    "default": {
      "url": "istiod.istio-system.svc.cluster.local:15010"
    }
  },
  "labels": {
    "group_by_k8s_service": "false"
  },
  "external_links": [
    {
      "title": "Istio Homepage",
      "url": "https://istio.io"
    }
  ]
}'

curl -X PUT localhost:9080/meshes/zone-default-zone -d '{
  "mesh_id": "zone-default-zone",
  "mesh_type": "greymatter",
  "name": "Grey Matter Core",
  "sessions": {
    "default": {
      "url": "control.default.svc:50000",
      "cluster": "edge",
      "zone": "zone-default-zone"
    }
  },
  "labels": {},
  "external_links": [
    {
      "title": "Grey Matter Home Page",
      "url": "https://greymatter.io"
    }
  ]
}
'
