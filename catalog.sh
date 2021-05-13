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

curl -X PUT localhost:9080/meshes/istio-demo/services/details-v1:9080 -d '{
    "service_id": "details-v1:9080",
    "mesh_id": "istio-demo",
    "name": "Details",
    "version": "1.0",
    "description": "An Istio details service. The details microservice contains book information.",
    "owner": "Istio",
    "owner_url": "https://istio.io",
    "api_endpoint": "",
    "api_spec_endpoint": "",
    "capability": "Details",
    "runtime": "GO",
    "documentation": "",
    "prometheus_job": "details-v1:9080",
    "min_instances": 1,
    "max_instances": 1,
    "enable_instance_metrics": false,
    "enable_historical_metrics": false,
    "business_impact": "medium",
    "external_links": [
      {
        "title": "Istio Homepage",
        "url": "https://istio.io"
      }
    ],
    "mesh_type": "istio",
    "localities": ["us-east-1a.us-east-1"],
    "instances": [
      {
        "instance_id": "94bf3c25814e892cdb99318e085d9f9d",
        "session": "default",
        "locality": "us-east-1a.us-east-1",
        "metadata": {
          "istio_cluster": "outbound|9080||details.istio-services.svc.cluster.local",
          "k8s_deployment": "details-v1",
          "k8s_namespace": "istio-services",
          "k8s_service": "details"
        }
      }
    ],
    "metadata": {},
    "status": "stable"
  }'

curl -X PUT localhost:9080/meshes/istio-demo/services/productpage-v1:9080 -d '{
    "service_id": "productpage-v1:9080",
    "mesh_id": "istio-demo",
    "name": "Product Page",
    "version": "1.0",
    "description": "An Istio product page service. The productpage microservice calls the details and reviews microservices to populate the page.",
    "owner": "Istio",
    "owner_url": "https://istio.io",
    "api_endpoint": "",
    "api_spec_endpoint": "",
    "capability": "Product",
    "runtime": "GO",
    "documentation": "",
    "prometheus_job": "productpage-v1:9080",
    "min_instances": 1,
    "max_instances": 1,
    "enable_instance_metrics": false,
    "enable_historical_metrics": false,
    "business_impact": "medium",
    "external_links": [
      {
        "title": "Istio Homepage",
        "url": "https://istio.io"
      }
    ],
    "mesh_type": "istio",
    "localities": ["us-east-1b.us-east-1"],
    "instances": [
      {
        "instance_id": "32d8b95f1eaaddee68b0dfb7d6a12656",
        "session": "default",
        "locality": "us-east-1b.us-east-1",
        "metadata": {
          "istio_cluster": "outbound|9080||productpage.istio-services.svc.cluster.local",
          "k8s_deployment": "productpage-v1",
          "k8s_namespace": "istio-services",
          "k8s_service": "productpage"
        }
      }
    ],
    "metadata": {},
    "status": "stable"
  }'

curl -X PUT localhost:9080/meshes/istio-demo/services/ratings-v1:9080 -d '{
    "service_id": "ratings-v1:9080",
    "mesh_id": "istio-demo",
    "name": "Ratings",
    "version": "1.0",
    "description": "An Istio Ratings service",
    "owner": "Istio",
    "owner_url": "https://istio.io",
    "api_endpoint": "",
    "api_spec_endpoint": "",
    "capability": "Rating",
    "runtime": "GO",
    "documentation": "",
    "prometheus_job": "ratings-v1:9080",
    "min_instances": 1,
    "max_instances": 1,
    "enable_instance_metrics": false,
    "enable_historical_metrics": false,
    "business_impact": "low",
    "external_links": [
      {
        "title": "Istio Homepage",
        "url": "https://istio.io"
      }
    ],
    "mesh_type": "istio",
    "localities": ["us-east-1a.us-east-1"],
    "instances": [
      {
        "instance_id": "1654908974fa0d29273a8c09cf1d0a92",
        "session": "default",
        "locality": "us-east-1a.us-east-1",
        "metadata": {
          "istio_cluster": "outbound|9080||ratings.istio-services.svc.cluster.local",
          "k8s_deployment": "ratings-v1",
          "k8s_namespace": "istio-services",
          "k8s_service": "ratings"
        }
      }
    ],
    "metadata": {},
    "status": "stable"
  }'

curl -X PUT localhost:9080/meshes/istio-demo/services/reviews-v1:9080 -d '{
    "service_id": "reviews-v1:9080",
    "mesh_id": "istio-demo",
    "name": "Reviews",
    "version": "1.0",
    "description": "An Istio reviews service (v1.0). The reviews microservice contains book reviews. It also calls the ratings microservice.",
    "owner": "Istio",
    "owner_url": "https://istio.io",
    "api_endpoint": "",
    "api_spec_endpoint": "",
    "capability": "Reviews",
    "runtime": "GO",
    "documentation": "",
    "prometheus_job": "reviews-v1:9080",
    "min_instances": 1,
    "max_instances": 1,
    "enable_instance_metrics": false,
    "enable_historical_metrics": false,
    "business_impact": "low",
    "external_links": [
      {
        "title": "Istio Homepage",
        "url": "https://istio.io"
      }
    ],
    "mesh_type": "istio",
    "localities": ["us-east-1a.us-east-1"],
    "instances": [
      {
        "instance_id": "fbe805e4865355ecb8f541d3b4fdd1ea",
        "session": "default",
        "locality": "us-east-1a.us-east-1",
        "metadata": {
          "istio_cluster": "outbound|9080||reviews.istio-services.svc.cluster.local",
          "k8s_deployment": "reviews-v1",
          "k8s_namespace": "istio-services",
          "k8s_service": "reviews"
        }
      }
    ],
    "metadata": {},
    "status": "stable"
  }'

curl -X PUT localhost:9080/meshes/istio-demo/services/reviews-v2:9080 -d '{
    "service_id": "reviews-v2:9080",
    "mesh_id": "istio-demo",
    "name": "Reviews",
    "version": "2.0",
    "description": "An Istio reviews service (v2.0). The reviews microservice contains book reviews. It also calls the ratings microservice.",
    "owner": "Istio",
    "owner_url": "https://istio.io",
    "api_endpoint": "",
    "api_spec_endpoint": "",
    "capability": "Reviews",
    "runtime": "GO",
    "documentation": "",
    "prometheus_job": "reviews-v2:9080",
    "min_instances": 1,
    "max_instances": 1,
    "enable_instance_metrics": false,
    "enable_historical_metrics": false,
    "business_impact": "low",
    "external_links": [
      {
        "title": "Istio Homepage",
        "url": "https://istio.io"
      }
    ],
    "mesh_type": "istio",
    "localities": ["us-east-1b.us-east-1"],
    "instances": [
      {
        "instance_id": "1520b8403eeed1f2eb479c6033100007",
        "session": "default",
        "locality": "us-east-1b.us-east-1",
        "metadata": {
          "istio_cluster": "outbound|9080||reviews.istio-services.svc.cluster.local",
          "k8s_deployment": "reviews-v2",
          "k8s_namespace": "istio-services",
          "k8s_service": "reviews"
        }
      }
    ],
    "metadata": {},
    "status": "stable"
  }'

curl -X PUT localhost:9080/meshes/istio-demo/services/reviews-v3:9080 -d '{
    "service_id": "reviews-v3:9080",
    "mesh_id": "istio-demo",
    "name": "Reviews",
    "version": "3.0",
    "description": "An Istio reviews service (v3.0). The reviews microservice contains book reviews. It also calls the ratings microservice.",
    "owner": "Istio",
    "owner_url": "https://istio.io",
    "api_endpoint": "",
    "api_spec_endpoint": "",
    "capability": "Reviews",
    "runtime": "GO",
    "documentation": "",
    "prometheus_job": "reviews-v3:9080",
    "min_instances": 1,
    "max_instances": 1,
    "enable_instance_metrics": false,
    "enable_historical_metrics": false,
    "business_impact": "low",
    "external_links": [
      {
        "title": "Istio Homepage",
        "url": "https://istio.io"
      }
    ],
    "mesh_type": "istio",
    "localities": ["us-east-1a.us-east-1"],
    "instances": [
      {
        "instance_id": "6ab5c1d4bc9bf9b6b91a13c95410929f",
        "session": "default",
        "locality": "us-east-1a.us-east-1",
        "metadata": {
          "istio_cluster": "outbound|9080||reviews.istio-services.svc.cluster.local",
          "k8s_deployment": "reviews-v3",
          "k8s_namespace": "istio-services",
          "k8s_service": "reviews"
        }
      }
    ],
    "metadata": {},
    "status": "stable"
  }
}'
