# SPIRE

This Helm chart deploys the spire server and agent following the guidelines of the `spire-tutorials` example kubernetes template.

### Spire Helm Charts implementation details/configuration overview

We create the server as a StatefulSet using a PersistentVolumeClaim for data storage (aka. registration entries)

We then create the agent as a DaemonSet to run on each node, which assumes that internal node networking is not compromised but that the network is, which is one of the main use-cases of SPIRE and zero-trust mesh configuration. 

#### Server

The SPIRE server uses the `k8s-sat` NodeAttestor, which uses service account tokens to verify the identity of nodes. It can either use a local `service_account_key_file` or it can use the Token Review API if running inside or connected to a cluster via a kubeconfig file.

In our case, we just use the Token Review API using a in-cluster serviceAccount. To do this, the spire-server pod needs some additional permissions, namely auth-delegator. Additionally, "[Token review API validation for SAT attestor is available starting on SPIRE 0.8.0](https://github.com/spiffe/spire/issues/956#issuecomment-502122628)," so we need to use a recent version.

There are other deloyment considerations such as which storage plugins to use, and additional configuration options depending on the deployment environment (e.g. inside AWS)

**Note: Certs**

All SPIRE servers create a "trust bundle" on startup which they use to sign every SVID that they issue. By default it is just a random self-signed certificate. It looks like this: 

```
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number: 0 (0x0)
    Signature Algorithm: ecdsa-with-SHA384
        Issuer: C=US, O=SPIFFE
        Validity
            Not Before: Jul 29 19:38:07 2019 GMT
            Not After : Jul 30 19:38:17 2019 GMT
        Subject: C=US, O=SPIFFE
        Subject Public Key Info:
            Public Key Algorithm: id-ecPublicKey
                Public-Key: (384 bit)
                pub: 
                    04:d0:c0:95:b7:74:7f:84:85:f9:da:2c:b5:10:55:
                    ee:de:50:be:98:67:5f:cc:bc:4f:a0:3b:8b:d9:5b:
                    47:c6:22:5f:c4:8e:78:14:6f:14:75:ed:75:89:11:
                    49:57:5c:bd:4a:b4:19:2e:9d:03:bc:52:fe:57:9e:
                    0c:86:f2:91:64:fc:23:6c:48:15:cc:67:44:b4:97:
                    3c:ac:1d:16:9d:8a:d8:c5:ce:dd:6b:f9:c3:3e:dd:
                    54:0d:cf:7e:73:04:30
                ASN1 OID: secp384r1
                NIST CURVE: P-384
        X509v3 extensions:
            X509v3 Key Usage: critical
                Digital Signature, Certificate Sign, CRL Sign
            X509v3 Basic Constraints: critical
                CA:TRUE
            X509v3 Subject Key Identifier: 
                EB:7A:9F:24:24:25:52:61:40:38:74:83:DA:D3:B7:E3:4F:24:EA:88
            X509v3 Subject Alternative Name: 
                URI:spiffe://deciphernow.com
    Signature Algorithm: ecdsa-with-SHA384
         30:64:02:30:22:0d:33:87:f1:15:b5:b5:19:ff:44:0e:95:de:
         f0:8d:4f:9f:e5:6c:28:3c:b0:2a:52:ee:dd:4a:e0:49:7b:5f:
         d6:36:f9:c6:5d:7f:6c:9d:d4:a3:bc:9c:b3:0e:da:aa:02:30:
         3d:f6:b0:df:de:95:8b:9d:90:dc:90:e8:49:41:a0:1b:2e:7d:
         83:ff:b6:7b:39:a3:b5:ee:78:50:fb:6c:4a:5b:7d:f1:9d:2b:
         70:b6:b9:ba:6c:41:0b:4b:18:e7:d9:05
```

A naive/basic way of configuring the agents to trust the trust bundle would be to wait for the SPIRE server to start up and then export the trust bundle cert, and somehow mount it in the agent. In fact, a few SPIRE examples do this, and our SPIRE example in the `gm-control-api` repo also does this. However, this is an ineffective method.

This is why SPIRE supports the UpstreamCA plugin type, which will take in a public and private key of a upstream/already trusted CA and sign its trust bundle using that CA.

This means that if your agent has the upstream CA's public key/cert and trusts it, then it will also trust the SPIRE trust bundle.

#### Agent

The SPIRE agent uses the `k8s-sat` NodeAttestor, wxhich uses service account tokens to verify the identity of nodes using the Token Review API. It reads the serviceAccountToken from the default Kubernetes mount path and sends it to the SPIRE server. However, the serviceAccountToken does not contain any claims about the node/daemonset/pod running the agent which means **any** container that has access to the whitelisted serviceAccount can assume the identity of the agent. 

This means you must take extra care to secure the serviceAccount used for your agent pods.

The SPIRE agent uses the `k8s-sat` WorkloadAttestor, which creates selectors for many Kubernetes properties such as namespaces, node ids, etc.

It authenticates with and reads properties from `kubelet` to turn into selectors.

#### Registration entries

In order for a given workload to be able to recieve a SVID for its given SPIFFE ID, the SPIFFE ID, along with various selectors which verify the authenticity of the workload assuming its identity, need to be present in the SPIRE server as a registration entry. This is what enables workloads to get SVIDs.

Different organizations may have differing needs and levels of specificity in the selectors and security of registration entries.

Additionally, the types of selectors used in each registration entry may be different from deployment to deployment across Kubernetes, Docker, and even plain Unix server setups.

This means that for now, all registration entries need to be created by the SRE/DevOps team in the organization. However, this sort of manual configuration is exactly what these Helm charts hope to eliminate, so we provide a basic script to create registration entries for all the default Grey Matter services.

In the future, `gm-control`/`gm-control-api` may communicate directly with the SPIRE server using the Registration API to create a set of sensible default registration entries for both Unix and Kubernetes environments.

GM Control API and gm-control will also need to provide a good API for route-based secret management and allowing/disallowing TLS to specific services/clusters.

#### mTLS/Proxy configuration

Once they have SVIDs, the SPIRE agent automatically pushes them out as secrets through the Secret Discovery Service to the Envoy gm-proxy so that they can use the SVID certs as mTLS certs.

They are discovered by a dynamic discovery mechanism which is configured in GM Control API. Grey Matter assumes that the secrets (SVIDs) and thus the registration entries which allow access to the SVIDs already exist when Envoy tries to query them.

### Caveats

TLDR: the current state of SPIRE in Openshift is:

Needs modified Security Context Constraints in OpenShift for the spire-agent daemonset to have access to the hostNetwork (for accessing the kubelet port), hostPID, and hostPath volumes (for the Workload API/SDS socket).

#### Future possibilities

We cannot run SPIRE in Kubernetes/OpenShift and use their provided node attestors without the agent daemonset construct, as the current k8s nodeAttestor needs a certain level of "priveleged"/trusted access to both the kubelet and some way to communicate over UDS to workload pods.

Theoretically, both these problems could be solved, so we could run the agent as a daemonset, or even just in one pod, and then serve SDS over TLS and not UDS, if SPIRE was upgraded to do the following
- Just use a regular Kubernetes serviceAccount to read which pods are on which nodes, end create all of the selectors from that
- Then serve SDS over TLS. Currently I believe that the SPIRE agent only provides the Workload API over Unix Domain Socket, which is why it could (easily?) extend it to serve SDS over UDS. However, SDS over TLS would be a great feature enabling much better deployment models. 

These two steps would allow us to run the spire agent possibly as a single pod in the cluster. However, both these steps move SPIRE further away from the "node"/agent construct of SPIRE, which IMO is going to become obsolete as people try to add zero-trust to multiple different types of architectures.

See [this issue](https://github.com/DecipherNow/helm-charts/issues/180#issuecomment-521725383) for more background