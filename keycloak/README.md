# Deploying Keycloak

## Setup Grey Matter

### Install Cluster Using Buttermilk Sky

```bash
bs create-kops-cluster --name $NAME --vpc dev2 --publicSubnets
```

See [runbook](https://github.com/greymatter-io/buttermilk-sky/blob/master/docs/content/runbooks/kops_cluster.md) for more information


### Install Grey Matter

```bash
make secrets
make install
```
## Setup Keycloak

### Install Keycloak

```bash
make keycloak
```

### Login to Keycloak

Once installed, go to the keycloak admin console through the keycloak ingress:

```bash
echo "https://$(kubectl get svc keycloak-backend -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")/auth/admin/"
```

Since the certificates are self-signed, you may need to type `thisisunsafe` when you get to the page. See [thread](https://miguelpiedrafita.com/chrome-thisisunsafe) for chrome.

Enter credentials:

```bash
echo Username: user
echo Password: $(kubectl get secret --namespace default keycloak-backend -o jsonpath="{.data.admin-password}" | base64 --decode)
```

### Import Grey Matter Realm

Once logged in, hover over the "Master" realm and click "Add Realm."

![img](images/add_realm.png)

For the "name" field put `greymatter` and click "Create."

[img](images/create_realm.png)

Now click on "Import" on the left hand side of the page. Click on "select file" and select the file `path/to/helm-charts/keycloak/realms/greymatter.json` realm export file. Set the "if resource exists" dropdown to `Overwrite`:

[img](images/import.png)

Click "import". You should be taken to a screen which shows successful import / overwriting of data.

### Add Users

Run the script

```bash
(cd keycloak && ./scripts/add_users.sh)
```
Now in the "Users" tab on the left side of the page you should see a table of users. Each user is initialized with the password "password123"