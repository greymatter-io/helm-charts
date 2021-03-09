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

    ```bash
    kubectl apply -f kafka/configmap-b0.yaml
    kubectl apply -f kafka/configmap-b1.yaml
    kubectl apply -f kafka/configmap-b2.yaml
    kubectl apply -f kafka/svc-b0.yaml
    kubectl apply -f kafka/svc-b1.yaml
    kubectl apply -f kafka/svc-b2.yaml
    kubectl apply -f kafka/zk/zk0-configmap.yaml
    kubectl apply -f kafka/zk/zk1-configmap.yaml
    kubectl apply -f kafka/zk/zk2-configmap.yaml
    kubectl apply -f kafka/zk/zk0-svc.yaml
    kubectl apply -f kafka/zk/zk1-svc.yaml
    kubectl apply -f kafka/zk/zk2-svc.yaml
    kubectl apply -f kafka/kafka_template.yaml -n kafka
    ```


```bash
    kubectl delete -f kafka/configmap-b0.yaml
    kubectl delete -f kafka/configmap-b1.yaml
    kubectl delete -f kafka/configmap-b2.yaml
    kubectl delete -f kafka/svc-b0.yaml
    kubectl delete -f kafka/svc-b1.yaml
    kubectl delete -f kafka/svc-b2.yaml
    kubectl delete -f kafka/zk/zk0-configmap.yaml
    kubectl delete -f kafka/zk/zk1-configmap.yaml
    kubectl delete -f kafka/zk/zk2-configmap.yaml
    kubectl delete -f kafka/zk/zk0-svc.yaml
    kubectl delete -f kafka/zk/zk1-svc.yaml
    kubectl delete -f kafka/zk/zk2-svc.yaml
    kubectl delete -f kafka/kafka_template.yaml -n kafka
```

4. Wait for pods to reach running states

    ```bash
    kubectl get pod -w -n kafka
    ```

5. Install coughka deployment for testing

Run a kafka client and create any topics - by default in coughka we're using coughka-test-topic, so:

```bash
kubectl run kafka-observables-client --rm --tty -i --restart='Never' --image docker.io/bitnami/kafka:2.7.0-debian-10-r1 --namespace kafka --command -- bash
```

and then:

```bash
kafka-topics.sh --create --bootstrap-server kafka-broker-1.kafka.svc.cluster.local:9093 --topic coughka-test-topic
kafka-topics.sh --create --bootstrap-server kafka-broker-1.kafka.svc.cluster.local:9093 --topic kafka-protocol-topic
```

Kafka-protocol-topic may fail if its already been created by the observables filter.

Verify with:

```bash
kafka-topics.sh --list --zookeeper kafka-observables-zookeeper-headless.kafka.svc.cluster.local:2181
```

Exit the kafka client and configure the mesh for the incoming coughka/sidecar combo:

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

To view the observables, rerun the kafka client command and run the consumer:

```bash
kubectl run kafka-observables-client --rm --tty -i --restart='Never' --image docker.io/bitnami/kafka:2.7.0-debian-10-r1 --namespace kafka --command -- bash
```

```bash
kafka-console-consumer.sh --bootstrap-server kafka-broker-1.kafka.svc.cluster.local:9093 --topic kafka-protocol-topic
```
