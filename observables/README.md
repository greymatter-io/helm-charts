# Observables

This repo provides an easy way to deploy observables for the Grey Matter Service Mesh. Observables are made up of Kafka/Zookeeper, Elasticsearch, Logstash, Kibana, and a Kibana-proxy to add it into the service mesh.
Simply put:

- Configured sidecars emit events to Kafka topics
- These topics are consumed by Logstash (one logstash per topic) and publish a transformation to Elasticsearch
- Kibana makes the Elasticsearch data presentable
- Kibana-proxy allows Kibana to be exposed through the mesh.

## Install ELK Stack

To install the observables stack:

1. Determine which namespace you would like to install the stack into, by default it is `observables`. If you choose to install into namespace `observables`, you can move onto step 2.  Otherwise, make the following change:

  Change the values for [`ELASTICSEARCH_HOST` and `KAFKA_BOOTSTRAP_SERVERS` here](custom-values-files/logstash-values.yaml#L45) to `elasticsearch-master-headless.<OBSERVABLES-NAMESPACE>.svc` and `kafka-observables-headless.<OBSERVABLES-NAMESPACE>` respectively, replacing `<OBSERVABLES-NAMESPACE>` with your chosen namespace.

2. If your Grey Matter fabric installation exists in the `default` namespace, you can move onto step 3. Otherwise, make the following change:

  Change the value of the `xds_host` environment variable in `sidecar.envvars` [here](./custom-values-files/kibana-proxy-values.yaml#L10) to `control.<FABRIC-NAMESPACE>.svc`, replacing `<FABRIC-NAMESPACE>` with the namespace that your fabric installation is running.

3. Are you installing into an EKS environment?

   If yes:
   From the root directory of the helm-charts, fill in your namespace to install from step 1 and run:

   ```bash
   make observables EKS=true OBSERVABLES_NAMESPACE=<OBSERVABLES-NAMESPACE>
   ```

   If no:

   ```bash
   make observables EKS=false OBSERVABLES_NAMESPACE=<OBSERVABLES-NAMESPACE>
   ```

   If at any time you need to take down the ELK stack, run `make remove-observables OBSERVABLES_NAMESPACE=<OBSERVABLES-NAMESPACE>` from the root directory of the helm-charts.

4. Upgrade fabric and sense for your new namespace. Update the `global.yaml` file you used for your Grey Matter installation and add your observables namespace from step 1 to `global.control.additional_namespaces` [here](../global.yaml#L22). Now if you are using hosted charts in EKS (ie from the [Grey Matter Quickstart guide](https://docs.greymatter.io/v/1.3-beta/guides/installation-kubernetes)) run the following:

   ```bash
   helm upgrade fabric greymatter/fabric -f global.yaml --set=global.environment=eks
   helm upgrade sense greymatter/sense -f global.yaml --set=global.environment=eks --set=global.waiter.service_account.create=false
   ```

   Otherwise, if you are using local charts:

   ```bash
   helm upgrade fabric fabric -f global.yaml --set=global.environment=<ENV>
   helm upgrade sense sense -f global.yaml --set=global.environment=<ENV> --set=global.waiter.service_account.create=false
   ```

   This will allow Grey Matter Control to discover from your observables namespace, and will allow Prometheus to get metrics.

5. [Configure the kibana proxy](#configure-the-kibana-proxy).

Once you have done these 5 steps, you should be able to see `Kibana Observables Proxy` in the dashboard, and access it at path `/services/kibana-observables-proxy/7.1.0/`. If you run `kubectl get pods -n observables`, you should see something that looks like the following, with all pods running:

```bash
NAME                                        READY   STATUS    RESTARTS   AGE
elasticsearch-master-0                      1/1     Running   0          4m13s
kafka-observables-0                         1/1     Running   0          4m15s
kafka-observables-1                         1/1     Running   0          4m15s
kafka-observables-2                         1/1     Running   0          4m15s
kafka-observables-zookeeper-0               1/1     Running   0          4m15s
kafka-observables-zookeeper-1               1/1     Running   0          4m15s
kafka-observables-zookeeper-2               1/1     Running   0          4m15s
kibana-kibana-56b5c6f578-jb8fj              1/1     Running   0          4m11s
kibana-observables-proxy-7446c44d6b-g8kvq   1/1     Running   0          4m8s
logstash-logstash-0                         1/1     Running   0          4m9s
```

Now your ELK stack is ready to recieve observables! See [enabling the observables filter](#enabling-the-grey-matter-observables-filter) for how to configure it.

## Configure the Kibana Proxy

If you are using namespace `observables`, from the root directory of the helm-charts, run:

```bash
./observables/gm-config/json-builder.py
```

If you changed the namespace, or you want to change the display name of the Kibana Proxy on the dashboard (the default is `Kibana Observables Proxy`), fill in the arguments  between `<>` and run the following instead:

```bash
./observables/gm-config/json-builder.py <observables-namespace> '<Kibana Dashboard Name>'
```

It will prompt you with a question `Is SPIRE enabled? True or False:`, if your Grey Matter deployment is using SPIRE, type `True` and enter. Otherwise `False`.

If you already have created mesh configs, it will prompt you to overwrite them. Type `y` enter to do so. You will see:

```bash
Success! To apply, run './observables/gm-config/export/kibana-observables-proxy/create.sh'
```

To apply the mesh configs, make sure the CLI is configured in your terminal (run `greymatter list cluster` without errors to check), and run:

```bash
./observables/gm-config/export/kibana-observables-proxy/create.sh
```

Now you have configured the Kibana Proxy in the mesh! If you need to delete these objects from the mesh at any time you can run `./observables/gm-config/export/kibana-observables-proxy/delete.sh`.

## Enabling the Grey Matter observables filter

To configure a sidecar to emit observables you must define the filter as well as enable it.  In the sidecar's `listener` object that you wish to turn on observables, `greymatter edit listener listener-servicex` and add the following:

```yaml

  "active_http_filters": ["gm.metrics","gm.observables"], #appending gm.observables will enable it
  "http_filters": {
    # configure the filter
    "gm_observables": {
      "useKafka": true, # must be true to emit to kafka
      "topic": "fibonacci", #this will be your service's name
      "eventTopic": "observables", # this will typically be your namespace
      "kafkaServerConnection": "kafka-observables.<OBSERVABLES-NAMESPACE>.svc:9092" #this is the kafka that logstash is pointed towards
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
