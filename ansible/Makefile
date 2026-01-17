SHELL := /bin/bash
.ONESHELL:

INV     ?= inventories/hosts.ini
PB_FULL ?= playbooks/full.yml
LIMIT   ?=
TAGS    ?=
CHECK   ?= 0
DIFF    ?= 0
VERBOSE ?= 0
BECOME  ?= 0

UV := $(shell command -v uv 2>/dev/null)
ifeq ($(UV),)
  AP := ansible-playbook
  ANS := ansible
  LINT := ansible-lint
else
  AP := uv run ansible-playbook
  ANS := uv run ansible
  LINT := uv run ansible-lint
endif

AP_ARGS := -i $(INV) $(PB_FULL)
ifneq ($(strip $(LIMIT)),)
  AP_ARGS += -l $(LIMIT)
endif
ifneq ($(strip $(TAGS)),)
  AP_ARGS += --tags $(TAGS)
endif
ifeq ($(CHECK),1)
  AP_ARGS += --check
endif
ifeq ($(DIFF),1)
  AP_ARGS += --diff
endif
ifeq ($(BECOME),1)
  AP_ARGS += --ask-become-pass
endif
ifeq ($(VERBOSE),1)
  AP_ARGS += -v
endif
ifeq ($(VERBOSE),2)
  AP_ARGS += -vv
endif
ifeq ($(VERBOSE),3)
  AP_ARGS += -vvv
endif

.PHONY: lint run full client work uni admin testvm ping

lint:
	$(LINT) .

run:
	$(AP) $(AP_ARGS)

full:
	@$(MAKE) run

client:
	@$(MAKE) run LIMIT=client

work:
	@$(MAKE) run LIMIT=work

uni:
	@$(MAKE) run LIMIT=uni

admin:
	@$(MAKE) run LIMIT=admin

testvm:
	@$(MAKE) run LIMIT=testvm

ping:
	ANSIBLE_HOST_KEY_CHECKING=False uv run ansible -i $(INV) testvm -m ping

ping-all:
	ANSIBLE_HOST_KEY_CHECKING=False uv run ansible -i $(INV) all -m ping

ping-clients:
	ANSIBLE_HOST_KEY_CHECKING=False uv run ansible -i $(INV) clients -m ping
