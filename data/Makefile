WAITERSACHECK=$(shell kubectl get sa waiter-sa | tail -n +2 | awk '{if ($$1=="waiter-sa") print "present"}')
ifeq (${WAITERSACHECK},present)
	FLAG=--set=global.waiter.service_account.create=false
else
	FLAG=--set=global.waiter.service_account.create=true
endif

pwd_name := $(notdir $(PWD))

NAME:=data
CHART := .

ifeq ($(pwd_name),helm-charts)
	CHART=$@
	INSTALLDIR := data/
	DEPUPDIR := data
endif
ifeq ($(pwd_name),data)
	CHART= .
	INSTALLDIR := 
	DEPUPDIR := .
endif


.PHONY: gm-data
gm-data:
	helm install $(NAME) $(INSTALLDIR)$(CHART) --set=global.environment=kubernetes $(FLAG)

.PHONY: jwt
jwt:
	helm install $(NAME) $(INSTALLDIR)$(CHART) --set=global.environment=kubernetes $(FLAG)

.PHONY: jwt-gov
jwt-gov:
	helm install $(NAME) $(INSTALLDIR)$(CHART) --set=global.environment=kubernetes $(FLAG)

.PHONY: package-data
package-data:
	rm -f $(CHART)/charts/*
	helm dep up $(DEPUPDIR)

.PHONY: data
data: package-data
	helm install $(NAME) $(CHART) --set=global.environment=kubernetes $(FLAG)

.PHONY: remove-data
remove-data:
	helm uninstall $(NAME)