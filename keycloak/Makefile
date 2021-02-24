SHELL := /bin/bash
mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
current_dir := $(notdir $(patsubst %/,%,$(dir $(mkfile_path))))
NAME-KEYCLOAK := keycloak

pwd_name := $(notdir $(PWD))

.PHONY: keycloak
keycloak:
	helm install keycloak-backend bitnami/keycloak
	

.PHONY: remove-keycloak
remove-keycloak:
	helm uninstall keycloak-backend
	