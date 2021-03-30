# Install Kafka For "Full" Setup

This directory contains the files needed to install kafka with 3 brokers with a sidecar for each broker.  This will follow the pattern described in the full setup.

## Steps

1. Create kafka namespace and install mesh

    ```bash
    make k3d
    kubectl create namespace kafka
    make install
    ```

2. Create kafka namespace and add secrets

    ```bash
    kubectl get secret docker.secret -o yaml > kafka-docker-secret.yaml
    kubectl get secret sidecar-certs -o yaml > kafka-sidecar-certs.yaml
    sed -i '' 's/default/kafka/g' kafka-docker-secret.yaml
    sed -i '' 's/default/kafka/g' kafka-sidecar-certs.yaml
    kubectl apply -f kafka-docker-secret.yaml
    kubectl apply -f kafka-sidecar-certs.yaml
    ```

3. Install kafka/sidecars

    Apply gm config:

    ```bash
    for cl in kafka/zk/mesh/zk0/clusters/*.json; do greymatter create cluster < $cl; done
    for cl in kafka/zk/mesh/zk0/domains/*.json; do greymatter create domain < $cl; done
    for cl in kafka/zk/mesh/zk0/listeners/*.json; do greymatter create listener < $cl; done
    for cl in kafka/zk/mesh/zk0/proxies/*.json; do greymatter create proxy < $cl; done
    for cl in kafka/zk/mesh/zk0/routes/*.json; do greymatter create route < $cl; done
    for cl in kafka/zk/mesh/zk1/clusters/*.json; do greymatter create cluster < $cl; done
    for cl in kafka/zk/mesh/zk1/domains/*.json; do greymatter create domain < $cl; done
    for cl in kafka/zk/mesh/zk1/listeners/*.json; do greymatter create listener < $cl; done
    for cl in kafka/zk/mesh/zk1/proxies/*.json; do greymatter create proxy < $cl; done
    for cl in kafka/zk/mesh/zk1/routes/*.json; do greymatter create route < $cl; done
    for cl in kafka/zk/mesh/zk2/clusters/*.json; do greymatter create cluster < $cl; done
    for cl in kafka/zk/mesh/zk2/domains/*.json; do greymatter create domain < $cl; done
    for cl in kafka/zk/mesh/zk2/listeners/*.json; do greymatter create listener < $cl; done
    for cl in kafka/zk/mesh/zk2/proxies/*.json; do greymatter create proxy < $cl; done
    for cl in kafka/zk/mesh/zk2/routes/*.json; do greymatter create route < $cl; done
    ```

    Apply kafka broker mesh configs:

    ```bash
    for cl in kafka/mesh/b0/clusters/*.json; do greymatter create cluster < $cl; done
    for cl in kafka/mesh/b0/domains/*.json; do greymatter create domain < $cl; done
    for cl in kafka/mesh/b0/listeners/*.json; do greymatter create listener < $cl; done
    for cl in kafka/mesh/b0/proxies/*.json; do greymatter create proxy < $cl; done
    for cl in kafka/mesh/b0/routes/*.json; do greymatter create route < $cl; done
    for cl in kafka/mesh/b1/clusters/*.json; do greymatter create cluster < $cl; done
    for cl in kafka/mesh/b1/domains/*.json; do greymatter create domain < $cl; done
    for cl in kafka/mesh/b1/listeners/*.json; do greymatter create listener < $cl; done
    for cl in kafka/mesh/b1/proxies/*.json; do greymatter create proxy < $cl; done
    for cl in kafka/mesh/b1/routes/*.json; do greymatter create route < $cl; done
    for cl in kafka/mesh/b2/clusters/*.json; do greymatter create cluster < $cl; done
    for cl in kafka/mesh/b2/domains/*.json; do greymatter create domain < $cl; done
    for cl in kafka/mesh/b2/listeners/*.json; do greymatter create listener < $cl; done
    for cl in kafka/mesh/b2/proxies/*.json; do greymatter create proxy < $cl; done
    for cl in kafka/mesh/b2/routes/*.json; do greymatter create route < $cl; done
    ```

    And apply:

    ```bash
    kubectl apply -f kafka/svc-b0.yaml
    kubectl apply -f kafka/svc-b1.yaml
    kubectl apply -f kafka/svc-b2.yaml
    kubectl apply -f kafka/zk/zk0-svc.yaml
    kubectl apply -f kafka/zk/zk1-svc.yaml
    kubectl apply -f kafka/zk/zk2-svc.yaml
    kubectl apply -f kafka/kafka_template.yaml -n kafka
    ```

    Apply catalog clusters (and temp routes from edge):

    ```bash
    for cl in kafka/temp-edge/b0/clusters/*.json; do greymatter create cluster < $cl; done
    for cl in kafka/temp-edge/b0/rules/*.json; do greymatter create shared_rules < $cl; done
    for cl in kafka/temp-edge/b0/routes/*.json; do greymatter create route < $cl; done
    for cl in kafka/temp-edge/b1/clusters/*.json; do greymatter create cluster < $cl; done
    for cl in kafka/temp-edge/b1/rules/*.json; do greymatter create shared_rules < $cl; done
    for cl in kafka/temp-edge/b1/routes/*.json; do greymatter create route < $cl; done
    for cl in kafka/temp-edge/b2/clusters/*.json; do greymatter create cluster < $cl; done
    for cl in kafka/temp-edge/b2/rules/*.json; do greymatter create shared_rules < $cl; done
    for cl in kafka/temp-edge/b2/routes/*.json; do greymatter create route < $cl; done
    for cl in kafka/temp-edge/zk0/clusters/*.json; do greymatter create cluster < $cl; done
    for cl in kafka/temp-edge/zk0/rules/*.json; do greymatter create shared_rules < $cl; done
    for cl in kafka/temp-edge/zk0/routes/*.json; do greymatter create route < $cl; done
    for cl in kafka/temp-edge/zk1/clusters/*.json; do greymatter create cluster < $cl; done
    for cl in kafka/temp-edge/zk1/rules/*.json; do greymatter create shared_rules < $cl; done
    for cl in kafka/temp-edge/zk1/routes/*.json; do greymatter create route < $cl; done
    for cl in kafka/temp-edge/zk2/clusters/*.json; do greymatter create cluster < $cl; done
    for cl in kafka/temp-edge/zk2/rules/*.json; do greymatter create shared_rules < $cl; done
    for cl in kafka/temp-edge/zk2/routes/*.json; do greymatter create route < $cl; done
    greymatter create catalog_cluster < kafka/temp-edge/b0/catalog.json
    greymatter create catalog_cluster < kafka/temp-edge/b1/catalog.json
    greymatter create catalog_cluster < kafka/temp-edge/b2/catalog.json
    greymatter create catalog_cluster < kafka/temp-edge/zk0/catalog.json
    greymatter create catalog_cluster < kafka/temp-edge/zk1/catalog.json
    greymatter create catalog_cluster < kafka/temp-edge/zk2/catalog.json
    ```

4. Wait for pods to reach running states

    ```bash
    kubectl get pod -w -n kafka
    ```

5. Install coughka deployment for testing.


    ```bash
    for cl in kafka/coughka/mesh/clusters/*.json; do greymatter create cluster < $cl; done
    for cl in kafka/coughka/mesh/domains/*.json; do greymatter create domain < $cl; done
    for cl in kafka/coughka/mesh/listeners/*.json; do greymatter create listener < $cl; done
    for cl in kafka/coughka/mesh/proxies/*.json; do greymatter create proxy < $cl; done
    for cl in kafka/coughka/mesh/rules/*.json; do greymatter create shared_rules < $cl; done
    for cl in kafka/coughka/mesh/routes/*.json; do greymatter create route < $cl; done
    ```

    Install coughka into the default namespace:

    ```bash
    kubectl apply -f kafka/coughka/coughka-deployment.yaml
    ```

Once everything is running, there should be no errors in the coughka container logs.

```bash
kc logs -f deployment/coughka -c coughka
```

You can use a consumer to check the messages or go to `services/coughka/published` to see the list of messages being published by the coughka service and `/services/coughka/subscribed` to see the list of messages being consumed by the coughka service.

To view the observables, run the consumer:

```bash
kubectl exec -it kafka-observables-0-0 -n kafka -c kafka -- /opt/bitnami/kafka/bin/kafka-console-consumer.sh --bootstrap-server 127.0.0.1:9093  --topic kafka-protocol-topic --from-beginning
```

This will show the observables - there will be a number of plain TCP observables mixed in with the decoded kafka protocol.


To delete:

```bash
kubectl delete -f kafka/svc-b0.yaml
kubectl delete -f kafka/svc-b1.yaml
kubectl delete -f kafka/svc-b2.yaml
kubectl delete -f kafka/zk/zk0-svc.yaml
kubectl delete -f kafka/zk/zk1-svc.yaml
kubectl delete -f kafka/zk/zk2-svc.yaml
kubectl delete -f kafka/kafka_template.yaml -n kafka
```
