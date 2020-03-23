WAITERSACHECK=$(shell kubectl get sa waiter-sa | tail -n +2 | awk '{if ($$1=="waiter-sa") print "present"}')
ifeq (${WAITERSACHECK},present)
	FLAG=--set=global.waiter.service_account.create=false
else
	FLAG=--set=global.waiter.service_account.create=true
endif

.PHONY: edge
edge:
	helm install edge . --set=global.environment=kubernetes $(FLAG)

.PHONY: remove-edge
remove-edge:
	helm uninstall edge