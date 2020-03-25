mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
current_dir := $(notdir $(patsubst %/,%,$(dir $(mkfile_path))))

pwd_name := $(notdir $(PWD))

.PHONY: edge
edge:
	if [ "$(pwd_name)" == "edge" ]; then \
		echo "run in makefile directory"; \
		helm install edge . --set=global.environment=kubernetes; \
	else \
		echo "run in helm-charts top directory"; \
		helm install edge edge --set=global.environment=kubernetes; \
	fi

.PHONY: remove-edge
remove-edge:
	helm uninstall edge