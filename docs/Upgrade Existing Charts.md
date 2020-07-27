# Upgrading Existing Charts

## Prerequisites

- A helm deployed Grey Matter
- Helm v3+

## Details

If changes need to be made to the running version of Grey Matter, the `make` files have the ability to deploy the updates.  All Grey Matter version updates need to be made to the `global.yaml` or `values.yaml` files before the updates can be applied.

## Local Usage

1. `cd fabric`
2. `make upgrade-fabric`

Each chart (`fabric`, `sense`, `data`, `edge`) have an `upgrade-$chart` command.
