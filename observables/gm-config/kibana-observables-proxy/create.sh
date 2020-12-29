#!/bin/sh

greymatter create cluster < path-to-dir/00.cluster.json
greymatter create cluster < path-to-dir/00.cluster.edge.json
greymatter create domain < path-to-dir/01.domain.json
greymatter create listener < path-to-dir/02.listener.json
greymatter create proxy < path-to-dir/03.proxy.json
greymatter create shared_rules < path-to-dir/04.shared_rules.json
greymatter create shared_rules < path-to-dir/04.shared_rules.edge.json
greymatter create route < path-to-dir/05.route.json
greymatter create route < path-to-dir/05.route.edge.1.json
greymatter create route < path-to-dir/05.route.edge.2.json
greymatter create catalog_cluster < path-to-dir/06.catalog.json
