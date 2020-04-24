# Deploy with K3d

## Prerequisites

- Docker  (must have at least 13Gb of memory allocated)
- Helm 3

## Usage

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
