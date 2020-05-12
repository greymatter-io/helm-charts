# Observables

This repo provides an easy way to deploy observables for the Grey Matter Service Mesh. Observables are made up of Kafka/Zookeeper, Elasticsearch, Logstash, Kibana, and a Kibana-proxy to add it into the service mesh.
Simply put:

- Configured sidecars emit events to Kafka topics
- These topics are consumed by Logstash (one logstash per topic) and publish a transformation to Elasticsearch
- Kibana makes the Elastic search data presentable
- Kibana-proxy allows Kibana to be exposed through the mesh.

## TODO

1. Create SA to run observables.

## Requirements

- `docker.secret` with ability to pull images in namespace
- `sidecar-certs` secret in namespace (for kibana-proxy)
- Tiller service account added to namespace[tiller-account](#tiller-account)
- Helm installed in observable namespace [install-helm-into-namespace](#install-helm-into-namespace)
- [Identify namespace/project ID](#identify-namespace-id)
- Docker images that conform to openshift security [Dockerfile](#dockerfile)

### Tiller Account

- To add the super Tiller account to the cluster modify [tiller-sa.yaml](./tiller/tiller-sa.yaml) substituting in your namespace. Run `oc apply -f ./tiller-sa.yaml` to apply to cluster.

### Install Helm Into Namespace

- run `helm init --tiller-namespace <observables-namespace> --service-account tiller`
- Confirm tiller is running with `helm version --tiller-namespace <observables-namespace>`. It is running if you see a client and server lines

```console
Client: &version.Version{SemVer:"v2.14.2", GitCommit:"a8b13cc5ab6a7dbef0a58f5061bcc7c0c61598e7", GitTreeState:"clean"}
Server: &version.Version{SemVer:"v2.14.2", GitCommit:"a8b13cc5ab6a7dbef0a58f5061bcc7c0c61598e7", GitTreeState:"clean"}
```

### Identify Namespace ID

Get security ID by running `oc get project <your project name> -o yaml | grep openshift.io/sa.scc.uid-range | awk '{print $2}' - | cut -d / -f 1`. You will see output similar to `1000170000`.  In this case you would append `ID=1000170000` to make commands.

### Dockerfile

Openshift introduces a number of security restrictions on images. The [Elasticsearch Dockerfile](./dockerfiles/elasticsearch/Dockerfile) we provide add those changes on top of the stock image provided by elastic.

## All in One Install

- Edit Values files to point to docker images you would like kubernetes/ openshift to pull from.
- Edit `xds_host` in the [kibana proxy value file](./custom-values-files/kibana-proxy-values.yaml) to point to control's service.
- If deploying kibana outside the proxy namespace the extraEnvs's `SERVER_BASEPATH` will need to match the path defined in your `05.route.edge.1.json` [gm config](#add-kibana-proxy-to-dashboard).
- From inside the `observables` directory run `make CLUSTER_CMD=oc TILLER-NAMESPACE=<observables-namespace> ID=<id-from-requirements>`. This will deploy Kafka, Zookeeper, ElasticSearch, Logstash, Kibana, and Kibana-proxy into the observables namespace with values from [custom-values.files](./custom-calues-files).

### Mesh Updates (control/ prometheus)

- Update control to see your observables namespace by appending your namespace to th `GM_CONTROL_KUBERNETES_NAMESPACES` environment variable.
- In the `prometheus` cofigmap `prometheus.yaml` update this section to include those same namespaces:

```yaml
scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
  - job_name: kubernetes
    metrics_path: /prometheus
    kubernetes_sd_configs:
      - role: pod
        namespaces:
          names:
            - 'greymatter3'
            - 'observables' # add additional namespaces here
```

- Restart prometheus to pick up changes

## Alternative Installation

### Suggested Deployment

We suggest you deploy observables as a package into one namespace and then an instance of logstash that monitors specific namespaces into those namespaces.  This will allow developers in a rbac enforced cluster to monitor their own logstash instance to ensure events published to kafka are consumed by logstash.  By default logstash is setup to monitor kafka topics that match the namespace it is deployed into.

### Deploy ELK+ Stack (Elastic Search, Logstash, Kibana, Zookeeper, and Kafka)

To install services individually use:

1. `make kafka TILLER-NAMESPACE=observables CLUSTER_CMD=oc`
2. `make elasticsearch TILLER-NAMESPACE=observables CLUSTER_CMD=oc ID=<namespace-id#>`
3. `make kibana TILLER-NAMESPACE=observables CLUSTER_CMD=oc>`
4. `make logstash LOGSTASH-NAMESPACE=observables CLUSTER_CMD=oc ID=<namespace-id#>`

## Add Kibana-Proxy to dashboard

1. Inside `observables/gm-config` run `./json-builder.py` to create Grey Matter Mesh objects. You can include an argument or run it interactively.
2. Apply those Grey Matter Configuration files to the mesh. (Copy the `export/<name>` directory into `greymatter-json/<name>` then run `./create.sh <name>`).

## Configuration of proxy/sidecars

To configure a proxy to emit observables you must define the filter as well as enable it.

```yaml

  "active_proxy_filters": ["gm.metrics","gm.observables"], #appending gm.observables will enable it
  "proxy_filters": {
    # configure the filter
    "gm_observables": {
      "useKafka": true, # must be true to emit to kafka
      "topic": "fibonacci", #this will be your service's name
      "eventTopic": "fib-test", # this will typically be your namespace
      "kafkaServerConnection": "kafka-observables-0.kafka-observables.observables.svc:9092" #this is the kafka that logstash is pointed towards
    },
  }
```

## Removing Observables

The make file has the ability to remove the observables deployment as a whole or individual pieces.  To remove everything use `make destroy-observables TILLER_NAMESPACE=<observables-namespace>`.  To delete individual logstash deployments use `make delete-logstash LOGSTASH-NAMESPACE=<namespace-logstash-deployed-into>`

## Troubleshooting

### Ensure observables are being emitted and transformed

- In a kafka instance `cd /somepath/kafka/bin` in here you can use `./kafka-topics --list $KAFKA_CFG_ZOOKEEPER_CONNECT --list` to see if the eventTopic specified in your proxy configuration is being pushed to kafka.
- In the Logstash logs there will be an event displayed similar to this [example logstash logs](./static/example-logstash.txt). If this does not happen then there is an issue with logstash picking up the kafka event.
- In elastic search you can run `curl localhost:9200/_cat/indices` this will result in [example elasticsearch curl output](./static/example-elasticsearch.txt). Listing your kafka topics transformed w/ date-time.

### Elasticsearch virtual memory issue

Symptom:

- Readiness check fails
- Logs:

```console
{"type": "server", "timestamp": "2020-01-27T18:08:48,564Z", "level": "INFO", "component": "o.e.b.BootstrapChecks", "cluster.name": "elasticsearch", "node.name": "elasticsearch-master-0", "message": "bound or publishing to a non-loopback address, enforcing bootstrap checks" }
ERROR: [1] bootstrap checks failed
[1]: max virtual memory areas vm.max_map_count [65530] is too low, increase to at least [262144]
```

Solution:

- [Manually increase the virtual memory for the nodes elasticsearch is running on](https://discuss.opendistrocommunity.dev/t/max-virtual-memory-areas-max-map-count-65530-is-too-low/275)

- [Increase node memory vi openshift tuner resource](https://developers.redhat.com/blog/2019/11/12/using-the-red-hat-openshift-tuned-operator-for-elasticsearch/)

### GreyMatter Config issues

Symptoms:

- cannot connect to route your-host/services/kibana-proxy/7.1.0/
- from the edge run `curl localhost:8001/clusters | grep kibana` and it does not show an ip

```console
[2020-01-28 22:10:42.111][7][warning][config] [bazel-out/k8-fastbuild/bin/external/envoy/source/common/config/_virtual_includes/grpc_mux_subscription_lib/common/config/grpc_mux_subscription_impl.h:70] gRPC config for type.googleapis.com/envoy.api.v2.Listener rejected: Error adding/updating listener kibana-observables-proxy:9080: Failed to initialize cipher suites EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH
```

Solution:

Check the version of the control. If it is 1.1.0 or greater then you will need to remove the cipher filter from the `00.cluster.edge.json` and `01.domain.json` json as per [helm chart pr 412](https://github.com/DecipherNow/helm-charts/pull/412)
