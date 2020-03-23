WAITERSACHECK=$(shell kubectl get sa waiter-sa | tail -n +2 | awk '{if ($$1=="waiter-sa") print "present"}')
ifeq (${WAITERSACHECK},present)
	FLAG=--set=global.waiter.service_account.create=false
else
	FLAG=--set=global.waiter.service_account.create=true
endif

.PHONY: control
control:
	helm install fabric control --set=global.environment=kubernetes $(FLAG)

.PHONY: api
api:
	helm install fabric control-api --set=global.environment=kubernetes $(FLAG)

.PHONY: package-fabric
package-fabric:
	rm charts/*
	helm dep up .

.PHONY: fabric
fabric: package-fabric
	helm install fabric . --set=global.environment=kubernetes $(FLAG)

.PHONY: remove-fabric
remove-fabric:
	helm uninstall fabric