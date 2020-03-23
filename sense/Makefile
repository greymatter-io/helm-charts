
WAITERSACHECK=$(shell kubectl get sa waiter-sa | tail -n +2 | awk '{if ($$1=="waiter-sa") print "present"}')
ifeq (${WAITERSACHECK},present)
	FLAG=--set=global.waiter.service_account.create=false
else
	FLAG=--set=global.waiter.service_account.create=true
endif

.PHONY: catalog
catalog:
	helm install sense catalog --set=global.environment=kubernetes $(FLAG)

.PHONY: dashboard
dashboard:
	helm install sense dashboard --set=global.environment=kubernetes $(FLAG)

.PHONY: slo
slo:
	helm install sense slo --set=global.environment=kubernetes $(FLAG)

.PHONY: package-sense
package-sense:
	rm charts/*
	helm dep up .

.PHONY: sense
sense: package-sense
	helm install sense . --set=global.environment=kubernetes $(FLAG)

.PHONY: remove-sense
remove-sense:
	helm uninstall sense