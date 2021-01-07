# Observables

This repo provides an easy way to deploy observables for the Grey Matter Service Mesh. Observables are made up of Kafka/Zookeeper, Elasticsearch, Logstash, Kibana, and a Kibana-proxy to add it into the service mesh.
Simply put:

- Configured sidecars emit events to Kafka topics
- These topics are consumed by Logstash (one logstash per topic) and publish a transformation to Elasticsearch
- Kibana makes the Elasticsearch data presentable
- Kibana-proxy allows Kibana to be exposed through the mesh.

## Install ELK Stack

To install the observables stack:

1. If your Grey Matter fabric installation exists in the `default` namespace, you can move onto step 2. Otherwise, make the following change:

   Change the value of the `xds_host` environment variable in `sidecar.envvars` [here](./custom-values-files/kibana-proxy-values.yaml#L10) to `control.<FABRIC-NAMESPACE>.svc`, replacing `<FABRIC-NAMESPACE>` with the namespace that your fabric installation is running.

2. Are you installing into an EKS environment?

   If yes:

   From the root directory of the helm-charts, fill in your desired namespace to install observables (by default it is `observables`) and run:

   ```bash
   make observables EKS=true OBSERVABLES_NAMESPACE=<OBSERVABLES-NAMESPACE>
   ```

   If no:

   ```bash
   make observables EKS=false OBSERVABLES_NAMESPACE=<OBSERVABLES-NAMESPACE>
   ```

   If at any time you need to take down the ELK stack, run `make remove-observables OBSERVABLES_NAMESPACE=<OBSERVABLES-NAMESPACE>` from the root directory of the helm-charts. It may take the pods a few minutes to stabilize.

3. Upgrade fabric and sense for your new namespace. Update the `global.yaml` file you used for your Grey Matter installation and add your observables namespace from step 1 to `global.control.additional_namespaces` [here](../global.yaml#L22).

   Now upgrade your fabric and sense deployments.

   If you are running in eks:

   ```bash
   helm upgrade fabric fabric -f global.yaml --set=global.environment=eks
   helm upgrade sense sense -f global.yaml --set=global.environment=eks --set=global.waiter.service_account.create=false
   ```

   If you are not running in eks, change `--set=global.environment=eks` to your environment in the above and run.

   This will allow Grey Matter Control to discover from your observables namespace, and will allow Prometheus to get metrics.

4. Configure the Kibana proxy.

   > Note: These pathogen templates are for a SPIRE enabled deployment only.

   To generate mesh configurations for the kibana proxy, [get the pathogen binary](https://github.com/greymatter-io/pathogen-greymatter#get-pathogen) if you have not already, and run:

   ```bash
   pathogen generate 'git@github.com:greymatter-io/pathogen-greymatter//all?ref=release-2.3'  kibana-observables-proxy/
   ```

   There will be a series of prompts - answer them accordingly:

   1. serviceName = `kibana-observables-proxy`
   2. serviceHost = `kibana-kibana.observables.svc.cluster.local`
      - If you installed into a namespace other than `observables` replace `.observables.` with `.<your-namespace>.`
   3. servicePort = `5601`
   4. sidecarIngressPort = `10808`
   5. sidecarEgressPort = `10909`
   6. trustDomain = `quickstart.greymatter.io`
   7. zone = `zone-default-zone`
   8. displayName = `Kibana Observables Proxy` (or however you would like it to appear on it's card in the dashboard)
   9. version = `latest`
   10. owner = `Kibana`
   11. capability = `observables`
   12. documentation = `/services/kibana-observables-proxy/latest`
   13. minInstances = `1`
   14. maxInstances = `1`

   Once the templates are generated, they will be saved into the directory  `kibana-observables-proxy`. Make sure your CLI is configured (run `greymatter list zone`  without errors to check) and run the following to apply the configs:

   ```bash
   cd kibana-observables-proxy
   ./apply.sh
   cd ..
   ```

   Now you have configured the kibana dashboard!

Once you have completed these 4 steps, you should be able to see `Kibana Observables Proxy` (or whatever displayName you chose) in the dashboard, and access it at path `/services/kibana-observables-proxy/latest`. If you run `kubectl get pods -n observables`, you should see something that looks like the following, with all pods running:

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

## Enabling the Grey Matter observables filter

To configure a sidecar to emit observables you must define the filter as well as enable it.  In the sidecar's `listener` object that you wish to turn on observables, `greymatter edit listener <listener-key>` and add `"gm.observables"` to the list of `active_http_filters`, and the following configuration to the `http_filters` map so that it looks like:

```yaml
  ...
  "active_http_filters": [..., "gm.observables"],
  "http_filters": {
    ...
    # configure the filter
    "gm_observables": {
      "useKafka": true,
      "topic": "<service-name>",
      "eventTopic": "greymatter",
      "kafkaServerConnection": "kafka-observables.observables.svc:9092"
    }
  }
```

Make sure to leave `eventTopic` as `"greymatter"` as logstash is configured for this kafka event topic, but change `topic` to the desired topic for this service.

Once you have done this, if you make a request to the service on which you just enabled observables, it will emit the observables to your ELK stack and you can move on to [finish configuring kibana](#configure-kibana).

## Configure Kibana

Navigate back to your kibana proxy dashboard at `services/kibana-observables-proxy/latest` and go to the management panel (the bottom-most option on the left panel). You should see `ElasticSearch` and `Kibana` listed on the left. Click on Kibana - Index Patterns. On the far right, click `Create index pattern`. If you [enabled observables](#enabling-the-grey-matter-observables-filter) and made a request to your service, there should be some existing data with the pattern `greymatter-*`. In the index pattern, type `greymatter-`. Click through the next steps to create the index.

Once you have created the kibana index for `greymatter-`, you can use [Grey Matter Dashboarder](https://github.com/greymatter-io/dashboarder#dashboarder) to populate a Kibana dashboard. From the root directory of your helm-charts repo, run the following:

The password is `password`.

```bash
mkdir observables/certs
openssl pkcs12 -in certs/quickstart.p12 -cacerts -nokeys -out observables/certs/ca.crt
openssl pkcs12 -in certs/quickstart.p12 -clcerts -nokeys -out observables/certs/user.crt
openssl pkcs12 -in certs/quickstart.p12 -nocerts -nodes -out observables/certs/user.key
```

Then, to run the dashboarder service:

```bash
docker run --rm -v $(pwd)/observables/certs:/usr/local/dashboarder -e GREYMATTER_URL=https://$GREYMATTER_API_HOST/services/kibana-observables-proxy/latest/api/saved_objects/ docker.greymatter.io/internal/dashboarder generate greymatter
```

You should see the response:

```bash
Found the greymatter index
Templating the Visualization
Applying the service visualization
Applying the response_code visualization
Applying the request_per_hour visualization
Applying the total_requests visualization
Applying the user_dn visualization
Applying the x_real_ip visualization
Applying the service_user_dn visualization
Applying the popular_paths visualization
Applying the successful_requests visualization
Applying the path visualization
Applying the user_agent visualization
Templating the Dashboard
Applying the Dashboard
Completed
```

Now, you can navigate to the `Dashboard` pane in your Kibana observables proxy dashboard, and you will see `Greymatter Dashboard` as an option. Here you will be able to visualize your observables!

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

- cannot connect to route your-host/services/kibana-proxy/latest/
- from the edge run `curl localhost:8001/clusters | grep kibana` and it does not show an ip

```console
[2020-01-28 22:10:42.111][7][warning][config] [bazel-out/k8-fastbuild/bin/external/envoy/source/common/config/_virtual_includes/grpc_mux_subscription_lib/common/config/grpc_mux_subscription_impl.h:70] gRPC config for type.googleapis.com/envoy.api.v2.Listener rejected: Error adding/updating listener kibana-observables-proxy:9080: Failed to initialize cipher suites EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH
```

Solution:

Check the version of the control. If it is 1.1.0 or greater then you will need to remove the cipher filter from the `00.cluster.edge.json` and `01.domain.json` json as per [helm chart pr 412](https://github.com/DecipherNow/helm-charts/pull/412)
