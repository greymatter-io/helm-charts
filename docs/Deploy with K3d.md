# Deploy with K3d

## Prerequisites

- Docker (must have at least 13 GB of memory and 65 GB of disk allocated)
- Helm 3 (https://helm.sh/docs/intro/install/)
- k3d 3 (https://k3d.io/#installation)
- Grey Matter credentials

## Local Installation

1. Ensure you are logged into docker
  - `docker login docker.greymatter.io`
  - Enter your Grey Matter username and password
2. `make k3d` - creates a kubernetes (k3s) cluster locally
3. `export KUBECONFIG=$(k3d kubeconfig write greymatter)` - configures `kubectl` to use the local k3d cluster
4. `make credentials` - creates a git ignored file `credentials.yaml`
5. `make secrets` - inserts data from `credentials.yaml` and `secrets/values.yaml` into the cluster as secrets
6. `make install` - installs each helm chart (spire, fabric, edge, data, sense). This will take about 1.5 minutes.
7. `make gm-user-cert` - generates your certificate located at `./greymatter.p12`. Load this certificate into your browser. The password is `password`.
8. Open up <https://localhost:30000>


### Cluster Commands

- `make k3d` - Creates a k3s cluster locally
- `make destroy` - Deletes the local k3s cluster
- Start cluster `k3d cluster start greymatter` and `kubectl config use-context k3d-greymatter`
- Stop cluster `k3d cluster stop greymatter`

### Grey Matter Commands

- Create Credentials `make credentials`
  - To manually add credentials to mesh run `make secrets` this will be done automatically by the install target
- Install Grey Matter `make install`
  - Individual child-charts can be installed by navigating to those specific directories and using `make <chart-name>` ex: `make fabric`
  - Packaging sub charts can be accomplished with `make package-<chart-name>` ex: `make package-fabric`
- To template Grey Matter `make template`
  - Templating sub charts can be accomplished with `make template-<chart-name>` ex: `helm template-fabric`

### Uninstalling Grey Matter
There are several uninstall options:
- `make uninstall` - Uninstalls Grey Matter from the k3s cluster
- To remove individual child-charts run `make remove-<chart-name>` ex: `make remove-fabric`
- `make delete` - preforms an uninstall but also purges pvc and pods typically spared by helm.  Leaves secrets/credentials.
- `make destroy` - Deletes the k3s cluster, including the Grey Matter mesh. Essentially a wrapper for `k3d cluster delete greymatter`.

### Troubleshooting

If pods are being `Evicted` then check events by running `kubectl get events --sort-by=.metadata.creationTimestamp`. If you see pods failing due to `disk pressure` then you need to increase the amount of disk allocated to Docker. Go to Docker > Preferences > Resources, and increase the disk image size to 65 GB (sufficient at time of this writing).
