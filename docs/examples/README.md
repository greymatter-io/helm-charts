# Grey Matter Helm Examples

These examples show how to deploy Grey Matter on a variety of different environments.

So far, we have examples for:
 - EKS (Elastic Kubernetes Service) on AWS

## Installation steps

1. Edit your custom.yaml file with the key fields
2. Run `helm dep up`
3. Run `helm install ./ -f custom.yaml` in whatever service you are trying to deploy (usually `greymatter`)


It will take a few minutes to deploy Grey Matter, the Voyager operator, and finally the Voyager ingress, along with provisiong the load balancer.

Then at some point, if you run `kubectl describe ingresses.voyager.appscode.com`, it will give you the `Hostname` field which will have the public URL of your cluster. Now you can test the GM Dashboard, given you have the `quickstart.p12` certs for mutual TLS authentication installed in your browser at this URL: `$ELB_URL/services/dashboard/latest/`.

## Notes

### EKS

Key fields are `global.environment: kubernetes` and `voyager.cloudProvider: aws`. The first allows our helm charts to use Kubernetes instead of openshift, and secondly allows Voyager, the ingress proxy we use, to automatically provision AWS Elastic Load Balancers to expose your cluster to the internet. 

### Other cloud providers

By changing the `cloudProvider` field to whatever cloud provider you are using, you should be able to follow the same steps with any cloud provider without any issues.