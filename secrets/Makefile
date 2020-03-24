.PHONY: credentials
credentials:
	./../ci/scripts/build-credentials.sh

copy-credentials:
	@if [ -f ../credentials.yaml ] && [ ! -f ./credentials.yaml ]; then \
		echo "No credentials in secrets. Copying files from .."; \
		cp ../credentials.yaml .; \
	else \
		echo "Double check that you have a valid credentials.yaml in the project root or we can't pull any images";\
	fi

.PHONY: secrets
secrets: copy-credentials
	ls
	helm install secrets . -f credentials.yaml
	rm credentials.yaml

.PHONY: remove-secrets
remove-secrets:
	helm uninstall secrets
