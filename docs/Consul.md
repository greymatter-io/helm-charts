# Consul

- [Consul](#consul)
  - [Core Service Announcement](#core-service-announcement)
  - [Grey Matter Control Discovery](#grey-matter-control-discovery)
  - [Prometheus Discovery](#prometheus-discovery)
  - [Adding a New Service](#adding-a-new-service)
  - [Minikube Setup](#minikube-setup)

Grey Matter supports service discovery using [HashiCorp Consul](https://www.consul.io/docs/index.html). For a full walkthrough using Minikube, see [Minikube Setup](#minikube-setup).

## Core Service Announcement

In order to configure the Grey Matter Helm charts to announce core services to Consul, edit the `greymatter.yaml` file and set `global.consul.enabled` to true, set `global.consul.host` and `global.consul.port` to your Consul server host and port respectively.

The core services will then be configured to register in Consul with a tag `tbn-cluster`, metadata with value `metrics: 8081` and a TCP health check for the service.

The metadata `metrics` field maps to the metrics port for the service. In order to have Prometheus discover this service, this field **must** be set.

## Grey Matter Control Discovery

To enable Grey Matter Control (gm-control) to discover from Consul, uncomment the following environment variables and add their values to `control.control.envvars` in `greymatter.yaml`:

```yaml
gm_control_cmd:
  type: 'value'
  value: 'consul'
gm_control_consul_dc:
  type: 'value'
  value: '{consul_datacenter}'
gm_control_consul_hostport:
  type: 'value'
  value: '{consul_host}:{consul_port}'
```

## Prometheus Discovery

With `global.consul.enabled` set to true, Prometheus will be configured to scrape Consul for services that have a port value for `metrics` configured in their metadata. To add a service to be scraped by Prometheus, it must be registered in Consul with `metrics: {metrics_port}` configured in it's metadata.

## Adding a New Service

Similar to Core Service Announcement, when adding a new service to the mesh using Consul, the service **must** be registered with a tag `tbn-cluster` to be discovered by gm-control. Services also **must** be registered with a configuration of `"metrics": {metrics_port}` pointing to the metrics port for the service to be scraped by Prometheus.

## Minikube Setup

For a basic set up of Grey Matter and Consul in Minikube, follow the [Deploy with Minikube](./Deploy%20with%20Minikube.md) guide with the following injections:

1. Clone HashiCorp's Consul Helm chart repo <https://github.com/hashicorp/consul-helm> and configure it as desired.  To use Minikube, you must comment out the Affinity settings in the `consul-helm/values.yaml` file.

2. Setup and start Minikube and Helm using the guide. Before installing the Grey Matter Helm charts, run `helm install ./consul-helm --name consul` from the directory where you unpacked it.  This will deploy Consul servers to Minikube. Run `kubectl port-forward consul-consul-server-0 8500:8500` to view the Consul UI on <http://localhost:8500/ui/dc1/services>. Consul should be listed in the services section of the UI with three instances.

3. Configure the Grey Matter Helm charts as described above.  For this example, in `greymatter.yaml`, set `global.consul.enabled` to true and set `global.consul.consul_hostport` to `consul-consul-server:8500`. This will register the core services with Consul and configure Prometheus to scrape any services in Consul with metadata `"metrics": {PORT}` at the given port value. To configure gm-control to discover from Consul, add the following to `control.control.envvars`:

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

1. Now, install the Grey Matter Helm charts as described in the [Deploy with Minikube guide](./Deploy%20with%20Minikube.md#install). After a few minutes, you should see in the Consul UI the core services have been registered.

- To verify that gm-control is discovering from Consul, run `kubectl get pods` and `kubectl port-forward gm-control-api-{pod-hash} 5555:5555`.  Then, `greymatter list cluster` should show that the listed instances for the registered services are from Consul.

- To verify that Prometheus is discovering from Consul, run `kubectl get pods` and `kubectl port-forward prometheus-{pod-hash} 9090:9090`. Navigate to <http://localhost:9090/targets> and verify that the service metrics endpoints are listed under the Consul job.  Another way to check this is by accessing voyager-edge - after [this step](./Deploy%20with%20Minikube.md#ingress), change "`http`" of the given URL to "`https`" and navigate to <https://{voyager-edge_URL}/services/prometheus/latest/targets>.
