# Deploy with K3d

## Prerequisites

- Docker
- Helm 3

## Usage

### Cluster Command

- Start Cluster `make k3d`
- Delete Cluster `make destroy`

### Grey Matter Commands

- Create Credentials `make credentials`
- Install Grey Matter `make install`
  - Individual child-charts can be installed by navigating to those specific directories and using `make <chart-name>` ex: `make fabric`
  - Packaging sub charts can be accomplished with `make package-<chart-name>` ex: `make package-fabric`
- Uninstall Grey Matter `make uninstall`
  - To remove individual child-charts run `make remove-<chart-name>` ex: `make remove-fabric`
  - `make delete` will proform an uninstall but will also purge pvc and pods typically spared by helm
