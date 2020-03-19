# control-api

This Helm chart installs control-api in your Grey Matter cluster.

It is the core service mesh API server, which acts as the persistence layer for `gm-control`. You define all of your service mesh objects + configuration by interacting with `control-api`, either directly through the REST API, or by using the `greymatter` CLI.

This Helm chart both deploys it as a service, available by default at `control-api:5555`, but also bootstraps it with a basic mesh configuration based on the other Grey Matter services. It uses the list of services defined in `.Values.global.services` to automatically generate all of the relevant mesh configuration.