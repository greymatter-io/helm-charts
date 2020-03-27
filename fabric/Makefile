WAITERSACHECK=$(shell kubectl get sa waiter-sa | tail -n +2 | awk '{if ($$1=="waiter-sa") print "present"}')
ifeq (${WAITERSACHECK},present)
	FLAG=--set=global.waiter.service_account.create=false
else
	FLAG=--set=global.waiter.service_account.create=true
endif

pwd_name := $(notdir $(PWD))

NAME:=fabric
CHART := .

ifeq ($(pwd_name),helm-charts)
	CHART=$@
	INSTALLDIR := fabric/
	DEPUPDIR := data
endif
ifeq ($(pwd_name),fabric)
	CHART = .
	INSTALLDIR := 
	DEPUPDIR := .
endif

.PHONY: control
control:
	helm install $(NAME) $(INSTALLDIR)$(CHART) --set=global.environment=kubernetes $(FLAG)

.PHONY: control-api
control-api:
	helm install $(NAME) $(INSTALLDIR)$(CHART)  --set=global.environment=kubernetes $(FLAG)

.PHONY: package-fabric
package-fabric:
	rm -f $(CHART)/charts/*
	helm dep up $(DEPUPDIR)

.PHONY: fabric
fabric: package-fabric
	helm install $(NAME) $(CHART) --set=global.environment=kubernetes $(FLAG)

.PHONY: remove-fabric
remove-fabric:
	helm uninstall $(NAME)