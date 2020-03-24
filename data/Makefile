WAITERSACHECK=$(shell kubectl get sa waiter-sa | tail -n +2 | awk '{if ($$1=="waiter-sa") print "present"}')
ifeq (${WAITERSACHECK},present)
	FLAG=--set=global.waiter.service_account.create=false
else
	FLAG=--set=global.waiter.service_account.create=true
endif

.PHONY: gm-data
gm-data:
	helm install data gm-data --set=global.environment=kubernetes $(FLAG)

.PHONY: jwt
jwt:
	helm install data jwt --set=global.environment=kubernetes $(FLAG)

.PHONY: jwt-gov
jwt-gov:
	helm install data jwt-gov --set=global.environment=kubernetes $(FLAG)

.PHONY: package-data
package-data:
	rm charts/*
	helm dep up .

.PHONY: data
data: package-data
	helm install data . --set=global.environment=kubernetes $(FLAG)

.PHONY: remove-data
remove-data:
	helm uninstall data