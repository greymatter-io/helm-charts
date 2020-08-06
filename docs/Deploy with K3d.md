# Deploy with K3d

## Prerequisites

- Docker (must have at least 13 GB of memory and 65 GB of disk allocated)
- Helm 3

## Local Usage

1. `make k3d` - start a kubernetes cluster locally.
2. `export KUBECONFIG=$(k3d kubeconfig write greymatter)` - configures `kubectl` to use the local k3d cluster.
3. `make credentials` - creates a git ignored file `credentials.yaml`
4. `make secrets` - inserts data from `credentials.yaml` and `secrets/values.yaml` into the cluster as secrets
5. `make install` - installs each helm chart (spire, fabric, edge, data, sense). This will take about 1.5 minutes
6. Open up <https://localhost:30000> using the certificate `./certs/quickstart.p12`. The password is "password"
7. When you're ready, uninstall Grey Matter with `make uninstall`

### Cluster Command

- Start Cluster `make k3d` and run `kubectl config use-context greymatter`
- Delete Cluster `make destroy`

### Grey Matter Commands

- Create Credentials `make credentials`
  - To manually add credentials to mesh run `make secrets` this will be done automatically by the install target
- Install Grey Matter `make install`
  - Individual child-charts can be installed by navigating to those specific directories and using `make <chart-name>` ex: `make fabric`
  - Packaging sub charts can be accomplished with `make package-<chart-name>` ex: `make package-fabric`
- Uninstall Grey Matter `make uninstall`
  - To remove individual child-charts run `make remove-<chart-name>` ex: `make remove-fabric`
  - `make delete` will preform an uninstall but will also purge pvc and pods typically spared by helm.  Leaves secrets/credentials.
- To template Grey Matter `make template`
  - Templating sub charts can be accomplished with `make template-<chart-name>` ex: `helm template-fabric`

### Troubleshooting

If pods are being `Evicted` then check events by running `kubectl get events --sort-by=.metadata.creationTimestamp`. If you see pods failing due to `disk pressure` then you need to increase the amount of disk allocated to Docker. Go to Docker > Preferences > Resources, and increase the disk image size to 65 GB (sufficient at time of this writing).
