#!/bin/sh

greymatter delete cluster cluster-kibana-name
greymatter delete cluster edge-to-kibana-name-cluster
greymatter delete domain domain-kibana-name
greymatter delete listener listener-kibana-name
greymatter delete proxy proxy-kibana-name
greymatter delete shared_rules shared-rules-kibana-name
greymatter delete shared_rules edge-kibana-name-shared-rules
greymatter delete route route-kibana-name
greymatter delete route edge-kibana-name-route
greymatter delete route edge-kibana-name-route-2