# Observables

This repo provides an easy way to deploy observables for the Grey Matter Service Mesh. Observables are made up of Kafka/Zookeeper, Elasticsearch, Logstash, Kibana, and a Kibana-proxy to add it into the service mesh.
Simply put:

- Configured sidecars emit events to Kafka topics
- These topics are consumed by Logstash (one logstash per topic) and publish a transformation to Elasticsearch
- Kibana makes the Elasticsearch data presentable
- Kibana-proxy allows Kibana to be exposed through the mesh.

## TODO

1. Create SA to run observables.

## Requirements

- a namespace in which to apply the observables
- `docker.secret` with ability to pull images in namespace
- `sidecar-certs` secret in namespace (for kibana-proxy)

## All in One Install

To install the observables stack:

1. Edit the [values files](./custom-values-files) to point to docker images you would like kubernetes/ openshift to pull from and for any custom configurations.  Be sure to make the following changes:

   - If you plan to install in a namespace other than `observables`, [edit the extra envs for logstash](custom-values-files/logstash-values.yaml#L45) `ELASTICSEARCH_HOST` and `KAFKA_BOOTSTRAP_SERVERS` with values `elasticsearch-master-headless.<OBSERVABLES-NAMESPACE>.svc` and `kafka-observables-headless.<OBSERVABLES-NAMESPACE>.svc:9092` respectively.
   - If your Grey Matter Fabric deployment is running in a namespace that is not `default`, edit `xds_host` in the [kibana proxy value file](./custom-values-files/kibana-proxy-values.yaml) to point to control's service.
   - If you change the [kibana-observables-proxy name](./custom-values-files/kibana-proxy-values.yaml#L1), you must also change the environment variable `SERVER_BASEPATH` in the kibana values file [here](./custom-values-files/kibana-values.yaml#L12) to match the path defined in your `05.route.edge.1.json` [gm config](#add-kibana-proxy-to-dashboard).
  
2. Install. If you are deploying in an **eks environment**, add `EKS=true` to your make commands.

   From the base directory of the helm-charts, run:

   ```bash
   make observables OBSERVABLES_NAMESPACE= EKS=
   ```

   The namespace specified will be created and the necessary secrets will be applied if they are not already there. EKS defaults to false and  `OBSERVABLES_NAMESPACE` defaults to `observables`. You can remove from the base directory with `make remove-observables  OBSERVABLES_NAMESPACE=`.

3. Make the necessary [mesh updates to control/prometheus](#mesh-updates-control-prometheus).  To do this, add the observables namespace to `global.control.additional_namespaces` value in the [global.yaml](../global.yaml) file and upgrade fabric and sense:

   ```bash
   helm upgrade fabric fabric -f global.yaml
   helm upgrade sense sense -f global.yaml --set=global.waiter.service_account.create=false
   ```

   Then restart prometheus to pick up the changes.

4. [Configure the kibana-proxy.](#configure-the-kibana-proxy)

Once these 4 steps are done, and all of the pods are up in your observables namespace, you should be able to see the Kibana Proxy in the dashboard, and access it.  To start using the observables stack in your mesh, [configure services to use the observables filter](#configuring-the-grey-matter-observables-filter)

## Mesh Updates (control/ prometheus)

- Update control to see your observables namespace by appending your namespace to the `GM_CONTROL_KUBERNETES_NAMESPACES` environment variable.
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

## Configure the Kibana Proxy

cd into the `observables/gm-config` directory and run `./json-builder.py` to create Grey Matter Mesh objects. It will prompt you for the follwing:

- `Is SPIRE enabled? True or False:` indicate whether or not your Grey Matter deployment is using SPIRE.
- `Input the name of the kibana-proxy:` this should match the tag on the kibana-observables-proxy deployment `greymatter.io/control` (which isalso [this value](./custom-values-files/kibana-proxy-values.yaml#L1)).
- `Input the observables namespace:` the namespace you are deploying observables.
- `Input the display name:` the display name for the Kibana proxy in the dashboard.

Apply the configuration files to the mesh. Make sure the CLI is configured, cd into the `/export/<name>` directory with `<name>` of the kibana proxy you just created, and run:

```bash
./create.sh
```

If you need to delete these configurations at any time cd back into this directory and `./delete.sh`.

If the instance doesn't seem to be found (if it remains up red on the dashboard), check that the [mesh updates](#mesh-updates-control-prometheus) were made.

## Configuring the Grey Matter observables filter

To configure a sidecar to emit observables you must define the filter as well as enable it.  In the sidecar's `listener` object that you wish to turn on observables, `greymattter edit listener listener-servicex` and add the following:

```yaml

  "active_http_filters": ["gm.metrics","gm.observables"], #appending gm.observables will enable it
  "http_filters": {
    # configure the filter
    "gm_observables": {
      "useKafka": true, # must be true to emit to kafka
      "topic": "fibonacci", #this will be your service's name
      "eventTopic": "observables", # this will typically be your namespace
      "kafkaServerConnection": "kafka-observables.<OBSERABLES-NAMESPACE>.svc:9092" #this is the kafka that logstash is pointed towards
    },
  }
```

## Alternative Installation

### Suggested Deployment

We suggest you deploy observables as a package into one namespace and then an instance of logstash that monitors specific namespaces into those namespaces.  This will allow developers in a rbac enforced cluster to monitor their own logstash instance to ensure events published to kafka are consumed by logstash.  By default logstash is setup to monitor kafka topics that match the namespace it is deployed into.

### Deploy ELK+ Stack (Elastic Search, Logstash, Kibana, Zookeeper, and Kafka)

If you want to install the stack piece by piece, cd into the the `observables` directory and do the following:

1. `make namespace NAMESPACE=` for the namespace you wish to install into, it will default to `observables`.
2. `make secrets NAMESPACE=` to install the necessary secrets, this assumes you have a `credentials.yaml` file as created via the main `helm-charts/Makefile`
3. To install everything at once, run `make NAMESPACE= EKS=`. This will deploy Kafka, Zookeeper, ElasticSearch, Logstash, Kibana, and Kibana-proxy into the observables namespace with values from [custom-values.files](./custom-calues-files). EKS default to false.
4. To install each piece individually, use the following:

- `make kafka NAMESPACE= EKS=`
- `make elasticsearch NAMESPACE= EKS=`
- `make kibana NAMESPACE= EKS=`
- `make logstash LOGSTASH-NAMESPACE= EKS=`
- `make kibana-proxy NAMESPACE= EKS=`

Once this is done, make the necessary [mesh updates](#mesh-updates-control-prometheus) and [configure the kibana-proxy](#configure-the-kibana-proxy).

## Removing Observables

The make file has the ability to remove the observables deployment as a whole or individual pieces.  

From the root directory of the helm-charts, run `make remove-observables OBSERVABLES_NAMESPACE=`.

From the observables directory, to remove everything use `make destroy-observables NAMESPACE=<observables-namespace>`.  To delete individual deployments use:

- `make delete-kafka NAMESPACE=`
- `make delete-elasticsearch NAMESPACE=`
- `make delete-kibana NAMESPACE=`
- `make delete-logstash NAMESPACE=`
- `make delete-kibana-proxy NAMESPACE=`

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
