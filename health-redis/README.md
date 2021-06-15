# Redis with a sidecar for health checking

# Redis sidecar deployment

The external redis deployed here is `health-redis`, its mesh configs are in the `/mesh` directory. It uses SPIRE mTLS from proxies and has a network RBAC policy only allowing SAN regex match with the spiffe identity trust domain.

# Sidecar configurations to egress to redis

The directory `health-redis/redis_configs` contains the mesh configs to route each core service's sidecar to redis using an egress listener at `localhost:6379`. These configs are in the `redis_configs` directory and were generated using `redis` branch of the pathogen repo by running:

```bash
pathogen generate 'git@github.com:greymatter-io/pathogen-greymatter//redis-egress?ref=redis' health-redis/redis_configs/SERVICE-NAME/
```

There's an apply script in each service's directory that you can run, and then you will need to manually update the proxies by adding `listener-<SERVICENAME>-health-redis-egress` and `domain-<SERVICENAME>-health-redis-egress` to the listeners and domains.

Once this is done, you can add `"metrics_receiver_connection_string": "redis://:testpass@localhost:6379"` to the metrics config on that services ingress listener and the sidecar should begin to publish to redis through the egress tcp channel.

# Note on locking down for catalog read only

There was one last element to this task:

```diff
* figure out how to lock down read access to just catalog (that will be the only consumer of these metrics for now)
```

This I was unable to find a way to do using RBAC because it needs to be at the network level, and using the envoy rbac filter means we can't parse into the request the way we do in tcp metrics. One strategy I had considered but didn't follow through on was if there could be a way to open up two ports on redis, a read only and a write only (don't think this is possible), but if so we could direct catalog eventually to read via tcp channel from the read only port, and lock that listener down using RBAC to only allow catalog access.
