# Grey Matter Spire Configuration

All of the necessary configurations for spire can be found in `greymatter-spire.yaml`.

## Spire Configuration

To see specifics on Spire configuration, see the [Spire Server](https://github.com/spiffe/spire/blob/master/doc/spire_server.md)
and [Spire Agent](https://github.com/spiffe/spire/blob/master/doc/spire_agent.md) documentation.

Our configurations can be found in the [Spire server.conf](https://github.com/DecipherNow/helm-charts/blob/release-2.1/spire/templates/server-configmap.yaml), and [Spire agent.conf](https://github.com/DecipherNow/helm-charts/blob/release-2.1/spire/templates/agent-configmap.yaml).

The Spire Agent is run in a Daemonset, so a new agent is spun up for each kubernetes node.

## How to generate a new SPIFFE CA

```bash
openssl ecparam -noout -genkey -name secp384r1 -out spire-root.key.pem
openssl req -new -x509 -days 365 -key spire-root.key.pem -subj "/C=US/OU=SPIFFE" -out spire-root.cert.pem
```

## Grey Matter API Objects

Our helm charts are configured to set up the below configurations in `greymatter-spire.yaml` automatically.  When `.Values.global.spire.enabled` is set to true, the Grey Matter core services are configured as follows.

The mesh is configured to use spire through the `secrets` set on the Grey Matter cluster object and listener object.  The cluster object secret sets the spiffe certificate for the sidecar egress, and the listener secret sets the same for the ingress.  The secrets are configured for certificates to be fetched from the spire agent by Envoy's [Secret Discovery Service](https://www.envoyproxy.io/docs/envoy/v1.10.0/configuration/secret.html?highlight=sds).  See the api [spire documentation](https://github.com/DecipherNow/gm-control-api/tree/release-1.2/docs/mesh/configuration/security/spire)documentation for specific information on configuring the objects and secrets.

1. Every sidecar is configured with an environment variable, `SPIRE_PATH`, set to `/run/spire/socket/agent.sock`. This is the path to the workload API socket (where the workloads connect to the workload API) as set in the Spire Agent configuration.  Passing this variable to the sidecar will configure Envoy SDS to be served over the same domain socket as the Spire Agent.

2. On startup, every `edge-to-servicex-cluster` will be configured with a secret.  The secret set on these clusters configures edge egress to `servicex` to use a SPIFFE certificate with ID `spiffe://quickstart.greymatter.io/servicex/mTLS`, the secret looks like:

    ```json
    "secret": {
        "secret_key": "secret-{{.service.serviceName}}-secret",
        "secret_name": "spiffe://{{ .Values.global.spire.trustDomain }}/{{.service.serviceName}}/mTLS",
        "secret_validation_name": "spiffe://{{ .Values.global.spire.trustDomain }}",
        "ecdh_curves": [
            "X25519:P-256:P-521:P-384"
        ]
    }
    ```

3. Every `listener-servicex` listener will be configured with a corresponding secret. This configures `servicex` ingress to look for a SPIFFE certificate with SPIFFE ID `spiffe://quickstart.greymatter.io/servicex/mTLS`.  Thus allowing edge to sidecar communication for all of the core services in the mesh.

4. When `.Values.services.edge.ingress.secret.enabled`, the `domain-edge` will be configured with an [`ssl_config`](https://github.com/DecipherNow/gm-control-api/blob/release-1.2/docs/mesh/objects/domain.md#tls-configuration).  This sets a browser cert on edge ingress, allowing the user to access the edge node from the browser. This is the only certificate necessary to mount.

    **NOTE** The above 4 configurations have configured the mesh to accept a non-SPIFFE certificate to access edge from the browser, and to use SPIFFE certificates for all edge-to-sidecar communication.  Each sidecar is configured to speak plaintext to their service, so at this point all services are accessible from edge.  Now, there are some specific configurations necessary to allow a non-edge service to access another service in the mesh, as is necessary for GM Data to speak with the GM JWT Security service, as well as GM Catalog to use GM Data as its config source.  

5. A second domain/listener pair is created for each service in the mesh other than edge.  Since at this point each sidecar is looking for a SPIFFE certificate as its ingress, we need to open another ingress listener to allow only the microservice itself to speak plaintext back to the sidecar.  For each service, `domain-servicex-local` and `listener-servicex-local` are created and configured to open another sidecar listener at `127.0.0.1:10818` that allows the service to access the sidecar with plaintext at that address.  Then, internal routes are created for the above examples, using the local domain key.

### Adding a new Service

Follow the steps below to add a new service to the mesh and configure it to use SPIFFE/SPIRE.  This example is for the fibonacci service without internal routes. To adapt this for your service, replace `fibonacci` with your service name.

1. You will need to add three things to the deployment for your service.  First, add the following volume:

   ```yaml
     - name: spire-agent-socket
     hostPath:
       path: /run/spire/socket
       type: Directory
   ```

    Then, add the following volume mount to your sidecar container:

    ```yaml
      - name: spire-agent-socket
        mountPath: /run/spire/socket
        readOnly: true
    ```

    Lastly, add an environment variable to the sidecar container with name `SPIRE_PATH` and value `/run/spire/socket/agent.sock`.

2. Exec into the spire server pod, `kubectl exec -it server-0 /bin/sh`, and run the following to create SPIFFE certificate entries for your new service:

    ```bash
    /opt/spire/bin/spire-server \
        entry create \
        -parentID spiffe://quickstart.greymatter.io/nodes \
        -spiffeID spiffe://quickstart.greymatter.io/fibonacci \
        -selector k8s:pod-label:app:fibonacci \
        -selector k8s:ns:default \
        -dns fibonacci.quickstart.greymatter.io \
        -registrationUDSPath /tmp/spire/registration/registration.sock
    ```

    ```bash
    /opt/spire/bin/spire-server \
        entry create \
        -parentID spiffe://quickstart.greymatter.io/fibonacci \
        -spiffeID spiffe://quickstart.greymatter.io/fibonacci/mTLS \
        -selector k8s:ns:default \
        -dns fibonacci.quickstart.greymatter.io \
        -registrationUDSPath /tmp/spire/registration/registration.sock
    ```

3. Create your deployment, `kubectl apply -f fib.yaml`. Now, configure the mesh as usual, (follow the [training material](https://github.com/DecipherNow/workshops/blob/master/training/3.%20Grey%20Matter%20Service%20Deployment/Grey%20Matter%20Service%20Deployment%20Training.md#grey-matter-sidecar-configuration) for a guide on mesh objects), and add the following.

   - In your `edge-fibonacci-cluster`, add a secret configuration, and set `require_tls` to true::
  
    ```json
    "require_tls": true,
    "secret": {
      "secret_key": "secret-fibonacci-secret",
      "secret_name": "spiffe://quickstart.greymatter.io/fibonacci/mTLS",
      "secret_validation_name": "spiffe://quickstart.greymatter.io",
      "ecdh_curves": [
        "X25519:P-256:P-521:P-384"
      ]
    }
    ```

    - In your services' listener, in this example `fibonacci-listener`, add:

    ```json
        "secret": {
        "secret_key": "secret-fibonacci-secret",
        "secret_name": "spiffe://quickstart.greymatter.io/fibonacci/mTLS",
        "secret_validation_name": "spiffe://quickstart.greymatter.io",
        "ecdh_curves": [
            "X25519:P-256:P-521:P-384"
        ],
        "forward_client_cert_details": "SANITIZE_SET",
        "set_current_client_cert_details": {
            "uri": true
        }
      }
    ```

    After the mesh is configured, you should be able to access your service at `/services/fibonacci/1.0/` (or whatever path specified in the `edge-service-route` path).

4. Register the service with catalog, in this case, you will need to curl with the browser certificate originally configured on the edge node.  The call should look something like: `curl -XPOST https://host:port/services/catalog/latest/clusters --cert /etc/ssl/quickstart/certs/quickstart.crt --key /etc/ssl/quickstart/certs/quickstart.key -k -d "@entry.json"` where `entry.json` is your [catalog entry](https://github.com/DecipherNow/workshops/blob/master/training/3.%20Grey%20Matter%20Service%20Deployment/Grey%20Matter%20Service%20Deployment%20Training.md#catalog-service-configuration).

Now, you should see fibonacci in the dashboard and be able to access its endpoints!

## Troubleshooting

When we setup services to participate in the mesh, Spiffe identities are setup for them.  This means that the service will get a certificate that is made for that service.  As an example of probing into data, to verify that it is setup to use Spiffe:

```bash
# Find the sidecar for data
ubuntu@ip-172-31-23-183:~$ sudo docker ps | grep data | grep sidecar
91fb0f9935dd        f603d9788209                 "/bin/sh -c './gm-pr…"   About an hour ago   Up About an hour                        k8s_sidecar_data-internal-0_default_61570ccf-d5d7-4f95-87fd-991ca980d4df_0
42f73ab8a18e        f603d9788209                 "/bin/sh -c './gm-pr…"   About an hour ago   Up About an hour                        k8s_sidecar_data-0_default_32e31d2a-68c9-4ae3-9b4f-87b7bc336a53_0
```

Then we know where the sidecar is exposing its network ingress port.

```bash
ubuntu@ip-172-31-23-183:~$ sudo docker exec -ti k8s_sidecar_data-0_default_32e31d2a-68c9-4ae3-9b4f-87b7bc336a53_0 ifconfig eth0
eth0      Link encap:Ethernet  HWaddr 02:42:AC:11:00:12  
          inet addr:172.17.0.18  Bcast:172.17.255.255  Mask:255.255.0.0
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:53363 errors:0 dropped:0 overruns:0 frame:0
          TX packets:42836 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0 
          RX bytes:34726145 (33.1 MiB)  TX bytes:20288558 (19.3 MiB)
```

From here, we know that port 8080 is the network ingress port, and that 172.17.0.18 is where gm-data resides.  We can connect without proper credentials to just see _who_ the service claims to be, and _who_ it trusts to connect.

```bash
ubuntu@ip-172-31-23-183:~$ openssl s_client --connect 172.17.0.18:8080
CONNECTED(00000005)
depth=1 C = US, O = SPIFFE
verify error:num=20:unable to get local issuer certificate
---
Certificate chain
 0 s:C = US, O = SPIRE, CN = data.quickstart.greymatter.io
   i:C = US, O = SPIFFE
 1 s:C = US, O = SPIFFE
   i:C = US, O = SPIFFE
---
Server certificate
-----BEGIN CERTIFICATE-----
MIICODCCAb6gAwIBAgIQUgfReo3aOeYydZoRkNcpHDAKBggqhkjOPQQDAzAeMQsw
CQYDVQQGEwJVUzEPMA0GA1UEChMGU1BJRkZFMB4XDTE5MTIxNzIxMjAwNloXDTE5
MTIxNzIyMjAxNlowOjELMAkGA1UEBhMCVVMxDjAMBgNVBAoTBVNQSVJFMRswGQYD
VQQDExJkYXRhLmdyZXltYXR0ZXIuaW8wWTATBgcqhkjOPQIBBggqhkjOPQMBBwNC
AATW+tgjx+W4XrRKeDVLzEiXF8gPQPLdeuF3XVp+eQk1bxG+qJsyviN3FXqcf/T2
u6koGaKah/RPTdRn7nj43PHIo4HBMIG+MA4GA1UdDwEB/wQEAwIDqDAdBgNVHSUE
FjAUBggrBgEFBQcDAQYIKwYBBQUHAwIwDAYDVR0TAQH/BAIwADAdBgNVHQ4EFgQU
HCjXKKwaCggw3TK2JSoNwv/zWuwwHwYDVR0jBBgwFoAUMR7sRWmlb+bfVycwCjXr
GdXdCCswPwYDVR0RBDgwNoISZGF0YS5ncmV5bWF0dGVyLmlvhiBzcGlmZmU6Ly9n
cmV5bWF0dGVyLmlvL2RhdGEvbVRMUzAKBggqhkjOPQQDAwNoADBlAjEA7i3KkPea
VIV7T1H96ICRt2ZRxIGp688RRoJH+gRXWhy8nQYVThZNA212u3bDc7CkAjBfzvnT
GJROTXP8oyHC3gfecIF77ryXfElEm9pVWV3t83k4M1qaRgGxSPRqF6Fupdo=
-----END CERTIFICATE-----
subject=C = US, O = SPIRE, CN = data.quickstart.greymatter.io

issuer=C = US, O = SPIFFE

---
Acceptable client certificate CA names
C = US, O = SPIFFE
Requested Signature Algorithms: ECDSA+SHA256:RSA-PSS+SHA256:RSA+SHA256:ECDSA+SHA384:RSA-PSS+SHA384:RSA+SHA384:RSA-PSS+SHA512:RSA+SHA512:RSA+SHA1
Shared Requested Signature Algorithms: ECDSA+SHA256:RSA-PSS+SHA256:RSA+SHA256:ECDSA+SHA384:RSA-PSS+SHA384:RSA+SHA384:RSA-PSS+SHA512:RSA+SHA512
Peer signing digest: SHA256
Peer signature type: ECDSA
Server Temp Key: X25519, 253 bits
---
SSL handshake has read 1466 bytes and written 423 bytes
...
```

From here, we can see that:

- `C = US, O = SPIRE` is the name of the certificate authority root signer
- `C = US, O = SPIRE, CN = data.quickstart.greymatter.io` is the name of the certificate issued to this sidecar for its identity.

The job of Spiffe is to setup certificates for edge egress, to sidecar network ingress.  If we look at the certificate in detail, we can see that they are set to expire hourly.

```bash
ubuntu@ip-172-31-23-183:~$ openssl s_client --connect 172.17.0.18:8080 | openssl x509 -text | grep After
depth=1 C = US, O = SPIFFE
verify error:num=20:unable to get local issuer certificate
140286333182400:error:1409445C:SSL routines:ssl3_read_bytes:tlsv13 alert certificate required:../ssl/record/rec_layer_s3.c:1528:SSL alert number 116
            Not After : Dec 17 22:20:16 2019 GMT
```

A sidecar that is using Spire is reading from a Unix Socket.  The use of a Unix Socket helps to attest that this is the rightful owner of the certificates that it would pull off of this socket.

```bash
ubuntu@ip-172-31-23-183:~/helm-charts$ sudo docker exec -ti k8s_sidecar_data-0_default_32e31d2a-68c9-4ae3-9b4f-87b7bc336a53_0 ls -al /run/spire/sockets
total 4
drwxr-xr-x    2 root     root            60 Dec 17 19:50 .
drwxr-xr-x    3 root     root          4096 Dec 17 19:50 ..
srwxrwxrwx    1 root     root             0 Dec 17 19:50 agent.sock
ubuntu@ip-172-31-23-183:~/helm-charts$
```
