PROJECT ?= $(HOME)/Desktop/Oud_SmartShop/smartshoplist_v140
SCRIPT   = tools/web_build_deploy.sh

.PHONY: deploy-auto deploy-ghp deploy-docs serve

deploy-auto:
	OPEN_LOCAL=0 $(SCRIPT) --project "$(PROJECT)" --target auto

deploy-ghp:
	OPEN_LOCAL=0 $(SCRIPT) --project "$(PROJECT)" --target gh-pages

deploy-docs:
	OPEN_LOCAL=0 $(SCRIPT) --project "$(PROJECT)" --target docs

serve:
	$(SCRIPT) --project "$(PROJECT)"
