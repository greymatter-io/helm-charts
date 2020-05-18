# Caveats and Notes

## Deleting Install

To delete a deployment run `helm uninstall <release name>`.  This will delete everything in the release. If using OpenShift, you can use `oc get pods` and `oc get pvc` to check that the rescources in the deployment have been removed (persistent volumes seem to take longer than pods).

## Custom File

You can override configurations in the `values.yaml` file by including them in the `custom.yaml` file, the `example-custom.yaml` file can be used to start modifications from. To use a custom file you will need to pass a flag, `-f <custom_file>`.

To override values in a particular chart's values.yaml file you will need to include a line in the custom.yaml file similar to the following:

```yaml
<chart_directory>
  <chart name>
      <key_to_override>: <value>
```

The most important keys for a barebones deployment are described in Step #2: Configuration above.

## Jenkins Pipeline

- To change the branch jenkins builds from use `./change-build-branch.sh`. The script will ask if you want to change to master, then your current branch, then a manual entry. You must be logged in openshift for this to work.
- The CI pipeline can be skipped by including any of skip term ("ci skip", "skip ci", "ci-skip", "skip-ci").

## Troubleshooting

- Keep in mind that helm will not tear down any resources that it did not create in the firstplace. Therefore the best practice is to manage everything inside a project/namespace with helm or nothing at all.

## Sidecar environment variables

Currently, all sidecar environment variables are configured in the `values.yaml` file of each service and can be configured globally at `.Values.global.sidecar.envvars`. This allows for easy setting of mesh-wide defaults for sidecar environment variables but also for easy configuration for each service/subchart.

In The future, we hope that all environment variables, even for the services, are configured using the environment variables template, although for services it is more likely that the template will just read from the local subchart `values.yaml` file and not use any global defaults, as each services environment variables are most likely different.

This is implemented by a helper template (in  `templates/_helpers.tpl`) which loops over the global envvars and uses local ones if they are available. This means that to use a sidecar environment variable at the local level, its name and type must already be defined at the global level, however, a global default does not need to be set.

If no value is found, either at the local level or in a global default, the template will just ignore that environment variable.

To support deploying the services individually, we copy the `greymatter` `_envvars_.tpl` into each service's `template` folder, which allows Helm to see it even when it is note used as a subchart. The template determines that if the value `.Values.global.sidecar` is not set, then it will only use the local `.Values.sidecar` options.
To copy `_envvars.tpl`, run this command:

```sh
echo **/templates | xargs -n 1 | grep -v greymatter/ | xargs -I{} sh -c 'cp greymatter/templates/_envvars.tpl "$1"' -- {}
```
