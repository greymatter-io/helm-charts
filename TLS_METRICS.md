# Upgrading Sidecar Metrics to mTLS
The following document covers the steps required to upgrade the mesh to secure our custom metrics with mTLS. This document is not intended to provide step by step instructions for upgrading all services in an existing deployment, but rather step by step instructions for upgrading one serivce and prometheus.  Note that following these steps in a deployed environment will break prometheus scraping for all but the upgraded service as mTLS is enforced on all targets.

## Mesh Configuration
The steps below target the catalog service deployment as performed by Helm.

1. Modify the existing listener on the catalog sidecar so that the metrics filter only binds to the loopback interface on a new port. Note that the only changes made to this configuration is the value of `http_filters.gm_metrics.metrics_host` and `http_filters.gm_metrics.metrics_port`.  The exact value of the port is not important as long as port conflicts are avoided and you propogate these changes to other configurations within these instructions. After making this change, metrics collection will fail until the rest of this process is complete.
    ```
    {
        "listener_key": "listener-catalog",
        "zone_key": "zone-default-zone",
        "name": "catalog",
        "active_network_filters": null,
        "network_filters": null,
        "active_http_filters": [
            "gm.metrics",
            "gm.impersonation"
        ],
        "http_filters": {
            "gm_impersonation": {
            "servers": "C=US,ST=Virginia,L=Alexandria,O=Decipher Technology Studios,OU=Engineering,CN=edge|C=US,ST=Virginia,L=Alexandria,O=Decipher Technology Studios,OU=Engineering,CN=greymatter"
            },
            "gm_metrics": {
            "metrics_port": 28081,
            "metrics_host": "127.0.0.1",
            "metrics_dashboard_uri_path": "/metrics",
            "metrics_prometheus_uri_path": "/prometheus",
            "metrics_ring_buffer_size": 4096,
            "prometheus_system_metrics_interval_seconds": 15,
            "metrics_key_function": "depth",
            "metrics_key_depth": "3"
            }
        },
        "ip": "0.0.0.0",
        "port": 10808,
        "protocol": "http_auto",
        "domain_keys": [
            "domain-catalog"
        ],
        "tracing_config": null,
        "secret": {
            "secret_key": "",
            "secret_name": "",
            "secret_validation_name": "",
            "subject_names": null,
            "ecdh_curves": null,
            "set_current_client_cert_details": {
            "uri": false
            },
            "checksum": ""
        },
        "access_loggers": {
            "http_connection_loggers": {
            "disabled": false,
            "file_loggers": null,
            "http_grpc_access_loggers": null
            },
            "http_upstream_loggers": {
            "disabled": false,
            "file_loggers": null,
            "http_grpc_access_loggers": null
            }
        },
        "use_remote_address": false,
        "http_protocol_options": null,
        "http2_protocol_options": null,
        "stream_idle_timeout": "",
        "request_timeout": "",
        "drain_timeout": "",
        "delayed_close_timeout": ""
    }
    ```
1. Create a new cluster on the catalog sidecar that will communicate with the plaintext metrics endpoint on the sidecar.
    ```
    {
        "cluster_key": "catalog.metrics.cluster",
        "zone_key": "zone-default-zone",
        "name": "metrics",
        "require_tls": false,
        "secret": {
            "secret_key": "",
            "secret_name": "",
            "secret_validation_name": "",
            "subject_names": null,
            "ecdh_curves": null,
            "set_current_client_cert_details": {
            "uri": false
            },
            "checksum": ""
        },
        "ssl_config": null,
        "instances": [
            {
            "host": "127.0.0.1",
            "port": 28081,
            "metadata": null
            }
        ],
        "circuit_breakers": null,
        "outlier_detection": null,
        "health_checks": [],
        "lb_policy": "",
        "http_protocol_options": null,
        "http2_protocol_options": null,
        "protocol_selection": "",
        "ring_hash_lb_config": null,
        "original_dst_lb_config": null,
        "least_request_lb_config": null,
        "common_lb_config": null
    }
    ```
1. Create a new domain on the catalog sidecar that will handle metrics requests and requires client authentication.
    ```
    {
        "domain_key": "catalog.metrics.domain",
        "zone_key": "zone-default-zone",
        "name": "*",
        "port": 8081,
        "ssl_config": {
            "cipher_filter": "",
            "protocols": null,
            "cert_key_pairs": [
            {
                "certificate_path": "/etc/proxy/tls/sidecar/server.crt",
                "key_path": "/etc/proxy/tls/sidecar/server.key"
            }
            ],
            "require_client_certs": true,
            "trust_file": "/etc/proxy/tls/sidecar/ca.crt",
            "sni": null,
            "crl": {
            "filename": "",
            "inline_string": ""
            }
        },
        "redirects": null,
        "gzip_enabled": false,
        "cors_config": null,
        "aliases": null,
        "force_https": true,
        "custom_headers": null
    }
    ```
1. Create a new listener on the catalog sidecar that will handle metrics requests.
    ```
    {
        "listener_key": "catalog.metrics.listener",
        "zone_key": "zone-default-zone",
        "name": "catalog.metrics",
        "active_network_filters": null,
        "network_filters": null,
        "active_http_filters": [],
        "http_filters": {},
        "ip": "0.0.0.0",
        "port": 8081,
        "protocol": "http_auto",
        "domain_keys": [
            "catalog.metrics.domain"
        ],
        "tracing_config": null,
        "secret": {
            "secret_key": "",
            "secret_name": "",
            "secret_validation_name": "",
            "subject_names": null,
            "ecdh_curves": null,
            "set_current_client_cert_details": {
            "uri": false
            },
            "checksum": ""
        },
        "access_loggers": {
            "http_connection_loggers": {
            "disabled": false,
            "file_loggers": null,
            "http_grpc_access_loggers": null
            },
            "http_upstream_loggers": {
            "disabled": false,
            "file_loggers": null,
            "http_grpc_access_loggers": null
            }
        },
        "use_remote_address": false,
        "http_protocol_options": null,
        "http2_protocol_options": null,
        "stream_idle_timeout": "",
        "request_timeout": "",
        "drain_timeout": "",
        "delayed_close_timeout": ""
    }
    ```
1. Create a new shared rule on the catalog sidecar that will push requests to the new cluster.
    ```
    {
        "shared_rules_key": "catalog.metrics.rules",
        "name": "metrics",
        "zone_key": "zone-default-zone",
        "default": {
            "light": [
            {
                "constraint_key": "",
                "cluster_key": "catalog.metrics.cluster",
                "metadata": null,
                "properties": null,
                "response_data": {},
                "weight": 1
            }
            ],
            "dark": null,
            "tap": null
        },
        "rules": null,
        "response_data": {},
        "cohort_seed": null,
        "properties": null,
        "retry_policy": null
    }
    ```
1. Create a new route on the catalog sidecar that will push requests to the new shared rule.
    ```
    {
        "route_key": "catalog.metrics.route",
        "domain_key": "catalog.metrics.domain",
        "zone_key": "zone-default-zone",
        "path": "/",
        "route_match": {
            "path": "",
            "match_type": ""
        },
        "prefix_rewrite": "",
        "redirects": null,
        "shared_rules_key": "catalog.metrics.rules",
        "rules": null,
        "response_data": {},
        "cohort_seed": null,
        "retry_policy": null,
        "high_priority": false,
        "filter_metadata": null,
        "filter_configs": null,
        "timeout": "",
        "idle_timeout": "",
        "request_headers_to_add": null,
        "request_headers_to_remove": null,
        "response_headers_to_add": null,
        "response_headers_to_remove": null
    }
    ```
1. Modify the existing  proxy on the catalog sidecar so that the new listener and domain are referenced. Note that the only changes in this configuration are the addition of the `catalog.metrics.domain` and `catalog.metrics.listener`.
    ```
    {
        "proxy_key": "proxy-catalog",
        "zone_key": "zone-default-zone",
        "name": "catalog",
        "domain_keys": [
            "domain-catalog",
            "domain-catalog-egress",
            "catalog.metrics.domain"
        ],
        "listener_keys": [
            "listener-catalog",
            "listener-catalog-egress",
            "catalog.metrics.listener"
        ],
        "listeners": null,
        "upgrades": "",
        "active_proxy_filters": null,
        "proxy_filters": null,
        "protocols": null
    }
    ```
1. Modify the prometheus configuration `prometheus.yaml` to add a `tls_config` and `scheme` to the `gm-metrics-kubernetes` discovery job as shown below.
    ```
    apiVersion: v1
    kind: ConfigMap
    metadata:
      annotations:
        meta.helm.sh/release-name: sense
        meta.helm.sh/release-namespace: default
      creationTimestamp: "2020-09-29T15:10:07Z"
      labels:
        app.kubernetes.io/managed-by: Helm
      managedFields:
      - apiVersion: v1
        fieldsType: FieldsV1
        fieldsV1:
          f:data:
            .: {}
            f:prometheus.yaml: {}
            f:recording_rules.yaml: {}
          f:metadata:
            f:annotations:
              .: {}
              f:meta.helm.sh/release-name: {}
              f:meta.helm.sh/release-namespace: {}
            f:labels:
              .: {}
              f:app.kubernetes.io/managed-by: {}
        manager: Go-http-client
        operation: Update
        time: "2020-09-29T15:10:07Z"
      name: prometheus
      namespace: default
      resourceVersion: "1618"
      selfLink: /api/v1/namespaces/default/configmaps/prometheus
      uid: 0119dac2-63b9-4dfa-9d78-ea800daebeeb
    data:
      prometheus.yaml: |-
        global:
          scrape_interval:     5s
          evaluation_interval: 2m
    
        # References the recording rules YAML file below
        rule_files:
          - "/etc/prometheus/recording_rules.yaml"
    
        scrape_configs:
          - job_name: 'prometheus'
            static_configs:
              - targets: ['localhost:9090']
          - job_name: 'gm-metrics-kubernetes'
            metrics_path: /prometheus
            kubernetes_sd_configs:
              - role: pod
                namespaces:
                  names:
                    - "default"
            relabel_configs:
            # Drop all named ports that are not "metrics"
            - source_labels: ['__meta_kubernetes_pod_container_port_name']
              regex: 'metrics'
              action: 'keep'
            # Relabel Jobs to the service name and version of the zk path
            - source_labels: ['__meta_kubernetes_pod_label_greymatter_io_control']
              regex: '(.*)'
              target_label:  'job'
              #replacement:   '${1}'
              replacement:   '${1}'
            tls_config:
              ca_file: /etc/prometheus/tls/ca.crt
              cert_file: /etc/prometheus/tls/server.crt
              key_file: /etc/prometheus/tls/server.key
              server_name: greymatter
            scheme: https
          - job_name: 'envoy-metrics-kubernetes'
            metrics_path: /stats/prometheus
            kubernetes_sd_configs:
              - role: pod
                namespaces:
                  names:
                    - "default"
                
            relabel_configs:
            # Drop all named ports that are not "metrics"
            - source_labels: ['__meta_kubernetes_pod_container_port_name']
              regex: 'metrics'
              action: 'keep'
            # Relabel Jobs to the service name and version of the zk path
            - source_labels: ['__meta_kubernetes_pod_label_greymatter_io_control']
              regex: '(.*)'
              target_label:  'job'
              #replacement:   '${1}'
              replacement:   '${1}'
            - source_labels: ['__address__']
              regex: '(.*):(.*)'
              target_label:  '__address__'
              replacement:   '${1}:8001'
        
      recording_rules.yaml: |-
        # Dashboard version: 3.4.0
        # time intervals:
        # ["1h", "4h", "12h"]
        
        groups:
          # queries for overall services
          - name: overviewQueries
            rules:
              - record: overviewQueries:avgUpPercent:avg
                expr: avg by (job) (up)
              # avgResponseTimeByRoute
              - record: overviewQueries:avgResponseTimeByRoute_1h:avg
                expr: avg(rate(http_request_duration_seconds_sum{key!="all"}[1h]) / rate(http_request_duration_seconds_count{key!="all"}[1h]) * 1000 > 0) by (job, key)
              - record: overviewQueries:avgResponseTimeByRoute_4h:avg
                expr: avg(rate(http_request_duration_seconds_sum{key!="all"}[4h]) / rate(http_request_duration_seconds_count{key!="all"}[4h]) * 1000 > 0) by (job, key)
              - record: overviewQueries:avgResponseTimeByRoute_12h:avg
                expr: avg(rate(http_request_duration_seconds_sum{key!="all"}[12h]) / rate(http_request_duration_seconds_count{key!="all"}[12h]) * 1000 > 0) by (job, key)
                # numberOfRequestsByRoute
              - record: overviewQueries:numberOfRequestsByRoute_1h:sum
                expr: sum(floor(increase(http_request_duration_seconds_count[1h])) >= 1) by (job, key)
              - record: overviewQueries:numberOfRequestsByRoute_4h:sum
                expr: sum(floor(increase(http_request_duration_seconds_count[4h])) >= 1) by (job, key)
              - record: overviewQueries:numberOfRequestsByRoute_12h:sum
                expr: sum(floor(increase(http_request_duration_seconds_count[12h])) >= 1) by (job, key)
                # latencyByRoute
              - record: overviewQueries:latencyByRoute_1h:sum
                expr: sum without(instance, status)(rate(http_request_duration_seconds_count{key!="all"}[1h])) > 0
              - record: overviewQueries:latencyByRoute_4h:sum
                expr: sum without(instance, status)(rate(http_request_duration_seconds_count{key!="all"}[4h])) > 0
              - record: overviewQueries:latencyByRoute_12h:sum
                expr: sum without(instance, status)(rate(http_request_duration_seconds_count{key!="all"}[12h])) > 0
                # error percent
              - record: overviewQueries:errorPercent_1h:sum
                expr: sum(floor(increase(http_request_duration_seconds_count{status!~"2..|3..", key!="all"}[1h]) )) by (job) / sum(floor(increase(http_request_duration_seconds_count{key!="all"}[1h]) )) by (job) * 100
              - record: overviewQueries:errorPercent_4h:sum
                expr: sum(floor(increase(http_request_duration_seconds_count{status!~"2..|3..", key!="all"}[4h]) )) by (job) / sum(floor(increase(http_request_duration_seconds_count{key!="all"}[4h]) )) by (job) * 100
              - record: overviewQueries:errorPercent_12h:sum
                expr: sum(floor(increase(http_request_duration_seconds_count{status!~"2..|3..", key!="all"}[12h]) )) by (job) / sum(floor(increase(http_request_duration_seconds_count{key!="all"}[12h]) )) by (job) * 100

          # queries for each route
          - name: queriesByRoute
            rules:
              # error percent
              - record: queriesByRoute:errorPercent_1h:sum
                expr: sum(floor(increase(http_request_duration_seconds_count{status!~"2..|3..", key!="all"}[1h]) )) by (job, key, method) / sum(floor(increase(http_request_duration_seconds_count{key!="all"}[1h]) )) by (job, key, method) * 100
              - record: queriesByRoute:errorPercent_4h:sum
                expr: sum(floor(increase(http_request_duration_seconds_count{status!~"2..|3..", key!="all"}[4h]) )) by (job, key, method) / sum(floor(increase(http_request_duration_seconds_count{key!="all"}[4h]) )) by (job, key, method) * 100
              - record: queriesByRoute:errorPercent_12h:sum
                expr: sum(floor(increase(http_request_duration_seconds_count{status!~"2..|3..", key!="all"}[12h]) )) by (job, key, method) / sum(floor(increase(http_request_duration_seconds_count{key!="all"}[12h]) )) by (job, key, method) * 100
                # p95Latency
              - record: queriesByRoute:p95Latency_1h:sum
                expr: round(histogram_quantile(0.95,avg without(instance, status)(rate(http_request_duration_seconds_bucket[1h]))) * 1000, 0.1)
              - record: queriesByRoute:p95Latency_4h:sum
                expr: round(histogram_quantile(0.95,avg without(instance, status)(rate(http_request_duration_seconds_bucket[4h]))) * 1000, 0.1)
              - record: queriesByRoute:p95Latency_12h:sum
                expr: round(histogram_quantile(0.95,avg without(instance, status)(rate(http_request_duration_seconds_bucket[12h]))) * 1000, 0.1)
                # p50 latency
              - record: queriesByRoute:p50Latency_1h:sum
                expr: round(histogram_quantile(0.50,avg without(instance, status)(rate(http_request_duration_seconds_bucket[1h]))) * 1000, 0.1)
              - record: queriesByRoute:p50Latency_4h:sum
                expr: round(histogram_quantile(0.50,avg without(instance, status)(rate(http_request_duration_seconds_bucket[4h]))) * 1000, 0.1)
              - record: queriesByRoute:p50Latency_12h:sum
                expr: round(histogram_quantile(0.50,avg without(instance, status)(rate(http_request_duration_seconds_bucket[12h]))) * 1000, 0.1)
                # request count for route
              - record: queriesByRoute:requestCount_1h:sum
                expr: sum(floor(increase(http_request_duration_seconds_count[1h])) >= 1) by (job, key, method)
              - record: queriesByRoute:requestCount_4h:sum
                expr: sum(floor(increase(http_request_duration_seconds_count[4h])) >= 1) by (job, key, method)
              - record: queriesByRoute:requestCount_12h:sum
                expr: sum(floor(increase(http_request_duration_seconds_count[12h])) >= 1) by (job, key, method)

            # range queries
          - name: rangeQueries
            rules:
              # pXXLatency range queries
              - record: rangeQueries:p50Latency:sum
                expr: round(histogram_quantile(0.50,avg without(instance, status)(rate(http_request_duration_seconds_bucket[10m]))) * 1000, 0.1)
              - record: rangeQueries:p90Latency:sum
                expr: round(histogram_quantile(0.90,avg without(instance, status)(rate(http_request_duration_seconds_bucket[10m]))) * 1000, 0.1)
              - record: rangeQueries:p95Latency:sum
                expr: round(histogram_quantile(0.95,avg without(instance, status)(rate(http_request_duration_seconds_bucket[10m]))) * 1000, 0.1)
              - record: rangeQueries:p99Latency:sum
                expr: round(histogram_quantile(0.99,avg without(instance, status)(rate(http_request_duration_seconds_bucket[10m]))) * 1000, 0.1)
              - record: rangeQueries:p999Latency:sum
               expr: round(histogram_quantile(0.999,avg without(instance, status)(rate(http_request_duration_seconds_bucket[10m]))) * 1000, 0.1)
              - record: rangeQueries:p9999Latency:sum
                expr: round(histogram_quantile(0.9999,avg without(instance, status)(rate(http_request_duration_seconds_bucket[10m]))) * 1000, 0.1)
                # error percent by (job, key)
              - record: rangeQueries:errorPercent:sum
                expr: sum(floor(increase(http_request_duration_seconds_count{status!~"2..|3..", key!="all"}[1m]) )) by (job, key) / sum(floor(increase(http_request_duration_seconds_count{key!="all"}[1m]) )) by (job, key) * 100
                # respones time per bucket
              - record: rangeQueries:responseTimeP50:sum
                expr: round(histogram_quantile(0.50,avg without(instance, status, key, method)(rate(http_request_duration_seconds_bucket{key!="all"}[10m]))) * 1000, 0.1)
              - record: rangeQueries:responseTimeP90:sum
                expr: round(histogram_quantile(0.90,avg without(instance, status, key, method)(rate(http_request_duration_seconds_bucket{key!="all"}[10m]))) * 1000, 0.1)
              - record: rangeQueries:responseTimeP95:sum
                expr: round(histogram_quantile(0.95,avg without(instance, status, key, method)(rate(http_request_duration_seconds_bucket{key!="all"}[10m]))) * 1000, 0.1)
              - record: rangeQueries:responseTimeP99:sum
                expr: round(histogram_quantile(0.99,avg without(instance, status, key, method)(rate(http_request_duration_seconds_bucket{key!="all"}[10m]))) * 1000, 0.1)
              - record: rangeQueries:responseTimeP999:sum
                expr: round(histogram_quantile(0.999,avg without(instance, status, key, method)(rate(http_request_duration_seconds_bucket{key!="all"}[10m]))) * 1000, 0.1)
              - record: rangeQueries:responseTimeP9999:sum
                expr: round(histogram_quantile(0.9999,avg without(instance, status, key, method)(rate(http_request_duration_seconds_bucket{key!="all"}[10m]))) * 1000, 0.1)
    
                # error violation
              - record: rangeQueries:errorViolation:sum
                expr: (1 - (sum without(instance, status, key, method)(rate(http_request_duration_seconds_count{key!="all",status=~"2..|3.."}[1m]))) / (sum without(instance, status, key, method)(rate(http_request_duration_seconds_count{key!="all"}[1m])))) * 100
                # requests violation
              - record: rangeQueries:requestRateViolation:sum
                expr: sum without(instance, status, key, method)(rate(http_request_duration_seconds_count{key!="all"}[1m]))
                # request violations for route violation
              - record: rangeQueries:routeRequestViolations:sum
                expr: sum without(instance, status, method)(rate(http_request_duration_seconds_count[1m]))
                # route latencies
              - record: rangeQueries:routep50LatencyViolations:sum
                expr: histogram_quantile(0.50,avg without(instance, status)(rate(http_request_duration_seconds_bucket[10m])))
              - record: rangeQueries:routep90LatencyViolations:sum
                expr: histogram_quantile(0.90,avg without(instance, status)(rate(http_request_duration_seconds_bucket[10m])))
              - record: rangeQueries:routep95LatencyViolations:sum
                expr: histogram_quantile(0.95,avg without(instance, status)(rate(http_request_duration_seconds_bucket[10m])))
              - record: rangeQueries:routep99LatencyViolations:sum
                expr: histogram_quantile(0.99,avg without(instance, status)(rate(http_request_duration_seconds_bucket[10m])))
              - record: rangeQueries:routep999LatencyViolations:sum
                expr: histogram_quantile(0.999,avg without(instance, status)(rate(http_request_duration_seconds_bucket[10m])))
              - record: rangeQueries:routep9999LatencyViolations:sum
                expr: histogram_quantile(0.9999,avg without(instance, status)(rate(http_request_duration_seconds_bucket[10m])))
    ```
1. Mount the required certificates into the prometheus container via the stateful set. Note that the only configuration change here is that the `sidecar-certs` volume is mounted to `/etc/prometheus/tls` in the `prometheus` container.  The volume already exists as it is used by the `sidecar` container.
```
apiVersion: apps/v1
kind: StatefulSet
metadata:
  annotations:
    meta.helm.sh/release-name: sense
    meta.helm.sh/release-namespace: default
  creationTimestamp: "2020-09-29T15:10:07Z"
  generation: 1
  labels:
    app.kubernetes.io/managed-by: Helm
  managedFields:
  - apiVersion: apps/v1
    fieldsType: FieldsV1
    fieldsV1:
      f:metadata:
        f:annotations:
          .: {}
          f:meta.helm.sh/release-name: {}
          f:meta.helm.sh/release-namespace: {}
        f:labels:
          .: {}
          f:app.kubernetes.io/managed-by: {}
      f:spec:
        f:podManagementPolicy: {}
        f:replicas: {}
        f:revisionHistoryLimit: {}
        f:selector:
          f:matchLabels:
            .: {}
            f:deployment: {}
            f:greymatter.io/control: {}
        f:serviceName: {}
        f:template:
          f:metadata:
            f:labels:
              .: {}
              f:deployment: {}
              f:greymatter.io/control: {}
          f:spec:
            f:containers:
              k:{"name":"prometheus"}:
                .: {}
                f:args: {}
                f:command: {}
                f:image: {}
                f:imagePullPolicy: {}
                f:name: {}
                f:ports:
                  .: {}
                  k:{"containerPort":9090,"protocol":"TCP"}:
                    .: {}
                    f:containerPort: {}
                    f:name: {}
                    f:protocol: {}
                f:resources:
                  .: {}
                  f:limits:
                    .: {}
                    f:cpu: {}
                    f:memory: {}
                  f:requests:
                    .: {}
                    f:cpu: {}
                    f:memory: {}
                f:terminationMessagePath: {}
                f:terminationMessagePolicy: {}
                f:volumeMounts:
                  .: {}
                  k:{"mountPath":"/etc/prometheus"}:
                    .: {}
                    f:mountPath: {}
                    f:name: {}
                  k:{"mountPath":"/var/lib/prometheus/data"}:
                    .: {}
                    f:mountPath: {}
                    f:name: {}
              k:{"name":"sidecar"}:
                .: {}
                f:env:
                  .: {}
                  k:{"name":"ENVOY_ADMIN_LOG_PATH"}:
                    .: {}
                    f:name: {}
                    f:value: {}
                  k:{"name":"PROXY_DYNAMIC"}:
                    .: {}
                    f:name: {}
                    f:value: {}
                  k:{"name":"XDS_CLUSTER"}:
                    .: {}
                    f:name: {}
                    f:value: {}
                  k:{"name":"XDS_HOST"}:
                    .: {}
                    f:name: {}
                    f:value: {}
                  k:{"name":"XDS_NODE_ID"}:
                    .: {}
                    f:name: {}
                    f:value: {}
                  k:{"name":"XDS_PORT"}:
                    .: {}
                    f:name: {}
                    f:value: {}
                  k:{"name":"XDS_ZONE"}:
                    .: {}
                    f:name: {}
                    f:value: {}
                f:image: {}
                f:imagePullPolicy: {}
                f:name: {}
                f:ports:
                  .: {}
                  k:{"containerPort":8081,"protocol":"TCP"}:
                    .: {}
                    f:containerPort: {}
                    f:name: {}
                    f:protocol: {}
                  k:{"containerPort":10808,"protocol":"TCP"}:
                    .: {}
                    f:containerPort: {}
                    f:name: {}
                    f:protocol: {}
                f:resources:
                  .: {}
                  f:limits:
                    .: {}
                    f:cpu: {}
                    f:memory: {}
                  f:requests:
                    .: {}
                    f:cpu: {}
                    f:memory: {}
                f:terminationMessagePath: {}
                f:terminationMessagePolicy: {}
                f:volumeMounts:
                  .: {}
                  k:{"mountPath":"/etc/proxy/tls/sidecar"}:
                    .: {}
                    f:mountPath: {}
                    f:name: {}
                    f:readOnly: {}
            f:dnsPolicy: {}
            f:imagePullSecrets:
              .: {}
              k:{"name":"docker.secret"}:
                .: {}
                f:name: {}
            f:restartPolicy: {}
            f:schedulerName: {}
            f:securityContext:
              .: {}
              f:fsGroup: {}
              f:runAsGroup: {}
              f:runAsUser: {}
            f:serviceAccount: {}
            f:serviceAccountName: {}
            f:terminationGracePeriodSeconds: {}
            f:volumes:
              .: {}
              k:{"name":"prometheus-configuration"}:
                .: {}
                f:configMap:
                  .: {}
                  f:defaultMode: {}
                  f:name: {}
                f:name: {}
              k:{"name":"sidecar-certs"}:
                .: {}
                f:name: {}
                f:secret:
                  .: {}
                  f:defaultMode: {}
                  f:secretName: {}
        f:updateStrategy:
          f:rollingUpdate:
            .: {}
            f:partition: {}
          f:type: {}
        f:volumeClaimTemplates: {}
    manager: Go-http-client
    operation: Update
    time: "2020-09-29T15:10:07Z"
  - apiVersion: apps/v1
    fieldsType: FieldsV1
    fieldsV1:
      f:status:
        f:collisionCount: {}
        f:currentReplicas: {}
        f:currentRevision: {}
        f:observedGeneration: {}
        f:readyReplicas: {}
        f:replicas: {}
        f:updateRevision: {}
        f:updatedReplicas: {}
    manager: k3s
    operation: Update
    time: "2020-09-29T15:10:39Z"
  name: prometheus
  namespace: default
  resourceVersion: "1824"
  selfLink: /apis/apps/v1/namespaces/default/statefulsets/prometheus
  uid: adfb8a53-76f2-4818-9d86-8bd8bd2a0a25
spec:
  podManagementPolicy: OrderedReady
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      deployment: prometheus
      greymatter.io/control: prometheus
  serviceName: prometheus
  template:
    metadata:
      creationTimestamp: null
      labels:
        deployment: prometheus
        greymatter.io/control: prometheus
    spec:
      containers:
      - args:
        - --query.timeout=4m
        - --query.max-samples=5000000000
        - --storage.tsdb.path=/var/lib/prometheus/data/data
        - --config.file=/etc/prometheus/prometheus.yaml
        - --web.console.libraries=/usr/share/prometheus/console_libraries
        - --web.console.templates=/usr/share/prometheus/consoles
        - --web.enable-admin-api
        - --web.external-url=http://anything/services/prometheus/latest
        - --web.route-prefix=/
        - --log.level=debug
        command:
        - /bin/prometheus
        image: prom/prometheus:v2.7.1
        imagePullPolicy: IfNotPresent
        name: prometheus
        ports:
        - containerPort: 9090
          name: http
          protocol: TCP
        resources:
          limits:
            cpu: "2"
            memory: 12Gi
          requests:
            cpu: "1"
            memory: 8Gi
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
        volumeMounts:
        - mountPath: /etc/prometheus
          name: prometheus-configuration
        - mountPath: /var/lib/prometheus/data
          name: prometheus-pvc
        - mountPath: /etc/prometheus/tls
          name: sidecar-certs
          readOnly: true
      - env:
        - name: ENVOY_ADMIN_LOG_PATH
          value: /dev/stdout
        - name: PROXY_DYNAMIC
          value: "true"
        - name: XDS_CLUSTER
          value: prometheus
        - name: XDS_HOST
          value: control.default.svc
        - name: XDS_NODE_ID
          value: default
        - name: XDS_PORT
          value: "50000"
        - name: XDS_ZONE
          value: zone-default-zone
        image: docker.greymatter.io/development/gm-proxy:1.4.5
        imagePullPolicy: IfNotPresent
        name: sidecar
        ports:
        - containerPort: 10808
          name: proxy
          protocol: TCP
        - containerPort: 8081
          name: metrics
          protocol: TCP
        resources:
          limits:
            cpu: 200m
            memory: 512Mi
          requests:
            cpu: 100m
            memory: 128Mi
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
        volumeMounts:
        - mountPath: /etc/proxy/tls/sidecar
          name: sidecar-certs
          readOnly: true
      dnsPolicy: ClusterFirst
      imagePullSecrets:
      - name: docker.secret
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext:
        fsGroup: 2000
        runAsGroup: 0
        runAsUser: 2000
      serviceAccount: prometheus-sa
      serviceAccountName: prometheus-sa
      terminationGracePeriodSeconds: 30
      volumes:
      - name: sidecar-certs
        secret:
          defaultMode: 420
          secretName: sidecar-certs
      - configMap:
          defaultMode: 420
          name: prometheus
        name: prometheus-configuration
  updateStrategy:
    rollingUpdate:
      partition: 0
    type: RollingUpdate
  volumeClaimTemplates:
  - apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      creationTimestamp: null
      name: prometheus-pvc
    spec:
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 80Gi
      volumeMode: Filesystem
    status:
      phase: Pending
```

