# Consul

Grey Matter supports service discovery from [Consul](https://www.consul.io/docs/index.html).  For a full walkthrough using minikube, see [Minikube Setup](#minikube).

## Core Service Announcement

In order to configure the Grey Matter helm charts to announce core services to Consul, edit the `greymatter.yaml` file and set `global.consul.enabled` to true, set `global.consul.consul_hostport` to your Consul server address.

The core services will then be configured to register in Consul in the form:

```json
{
  "Service": {
    "address": "{POD_IP}",
    "name": "name-of-core-service",
    "tags": ["tbn-cluster"],
    "port": 8080,
    "meta": {
        "metrics": 8081
    }
  }
}
```

Where the metadata has a `metrics` field mapping to the metrics port for the service. In order to have prometheus discover this service, this field **must** be set.


## GM-Control Discovery

To enable gm-control to discover from Consul, add the following environment variables to `control.control.envvars` in `greymatter.yaml`:

```yaml
      gm_control_cmd:
        type: 'value'
        value: 'consul'
      gm_control_consul_dc:
        type: 'value'
        value: '{your-consul_datacenter}'
      gm_control_consul_hostport:
        type: 'value'
        value: {your-consul_host:port}'
```

## Prometheus Discovery

With `global.consul.enabled` set to true, Prometheus will be configured to scrape consul for services that have a port value for `metrics` configured in their metadata. To add a service to be scraped by Prometheus, it must be registered in Consul with `metrics:{metricsPort}` configured in it's metadata.

## Note
When adding a new service to the mesh and using consul, keep in mind that services **must** be registered with a tag `tbn-cluster` to be discovered by gm-control. Services also **must** be registered with a metadata value `"metrics":{metrics_Port}` pointing to the metrics port for the service to be scraped by Prometheus. These are done automatically for the core services using the helm-charts.

### Minikube

For a basic set up of Grey Matter and Consul in Minikube, follow the [Deploy with Minikube](./Deploy%20with%20Minikube.md) guide with the following injections:

1. Clone hashicorp's consul helm chart repo https://github.com/hashicorp/consul-helm and configure it as desired.  To use minikube, you must comment out the Affinity settings in the `consul-helm/values.yaml` file. 


2. Setup and start minikube and helm using the guide. Before installing the Grey Matter helm charts, run `helm install ./consul-helm --name consul` from the directory where you unpacked it.  This will deploy Consul servers to minikube, run `kubectl port-forward consul-consul-server-0 8500:8500` to view to Consul UI on http://localhost:8500/ui/dc1/services. Consul should be listed in the services section of the UI, with 3 instances.

3. Configure the Grey Matter helm charts as described above.  For this example, in `greymatter.yaml`, set global.consul.enabled to true and set global.consul.consul_hostport to `consul-consul-server:8500`.  This will register the core services with Consul and configure prometheus to scrape any services in Consul with metadata `"metrics": {PORT}` at the given port value. To configure gm-control to discover from Consul, add the following to control.control.envvars:
```yaml
      gm_control_cmd:
        type: 'value'
        value: 'consul'
      gm_control_consul_dc:
        type: 'value'
        value: 'dc1'
      gm_control_consul_hostport:
        type: 'value'
        value: 'consul-consul-server:8500'
```

4. Now, install the Grey Matter helm charts as described in the minikube guide. After a few minutes, you should see in the consul UI the core services have been registered. 

* To verify that gm-control is discovering from Consul, run `kubectl get pods` and `kubectl port-forward {gm-control-api-PODname} 5555:5555`.  Then, `greymatter list cluster` should show that the listed instances for the registered services are from consul.

* To verify that prometheus is discovering from Consul, run `kubectl get pods` and `kubectl port-forward {prometheus-PODname} 9090:9090`. Navigate to http://localhost:9090/targets and verify that the service metrics endpoints are listed under the Consul job.