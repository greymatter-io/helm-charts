# Deploying Keycloak

## Deploy Buttermilk Sky cluster

See [runbook](https://github.com/greymatter-io/buttermilk-sky/blob/master/docs/content/runbooks/kops_cluster.md)

## Add Ingress

TODO

## Configure Keycloak

### Add Realm

	TODO

### Create Users

	TODO

## Setup Grey Matter to Use Keycloak

### Update Edge
	
	TODO


# Enabling in Production

Before you go and run Keycloak in production there are a few more things that you will want to do, including:

- Switch to a production ready database such as PostgreSQL

- Configure SSL with your own certificates

- Switch the admin password to a more secure password