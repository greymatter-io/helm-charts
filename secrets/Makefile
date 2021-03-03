include ../helpers.mk

NAME-SECRET:=secrets-$(CUST)

.PHONY: credentials secrets upgrade-secrets remove-secrets

credentials:
	@$(HOME)/ci/scripts/build-credentials.sh

copy-credentials:
	@cp $(HOME)/credentials.yaml .

template-secrets: $(BUILD_NUMBER_FILE)
	mkdir -p $(OUTPUT_PATH)
	helm template $(NAME-SECRET) . --set=global.environment=kubernetes   -f $(HOME)/credentials.yaml -f $(HOME)/global.yaml > $(OUTPUT_PATH)/helm-secrets$(BN).yaml

secrets: copy-credentials values-validation
	helm install $(NAME-SECRET) . -f credentials.yaml -f $(HOME)/global.yaml
	rm credentials.yaml

upgrade-secrets: copy-credentials values-validation
	helm upgrade $(NAME-SECRET) . -f credentials.yaml -f $(HOME)/global.yaml --install
	rm credentials.yaml

remove-secrets:
	helm uninstall $(NAME-SECRET)


values-validation:
	# Ensure that the rds.enabled is true in secrets and in fabric values files
	if [ "$(shell cat values.yaml | $(YQCMD) -r '.postgres.rds.enabled')" == "$(shell cat $(HOME)/sense/values.yaml | $(YQCMD) -r '.slo.postgres.rds.enabled')" ]; then \
		echo "rds.enabled in secrets/values.yaml and sense/values.yaml match"; \
	else \
		echo "rds.enabled in secrets/values.yaml and sense/values.yaml DO NOT MATCH.  Secrets will not be created"; \
		exit 2;\
	fi
