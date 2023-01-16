# ---------------------------------------------------------------------------------------- #
# -- < IaC > --
# ---------------------------------------------------------------------------------------- #
# -- terraform variables declaration
IAC_DIR = iac/
DBT_DIR = $(DBT_PROJECT)/
TF_DIR = $(IAC_DIR).terraform/
TF_INIT  = $(TF_DIR)terraform.tfstate
TF_VARS  = $(IAC_DIR)terraform.tfvars
TF_PLAN  = $(IAC_DIR)tfplan
TF_STATE = $(wildcard $(IAC_DIR)*.tfstate $(TF_DIR)*.tfstate)
TF_FILES = $(wildcard $(IAC_DIR)*.tf)

.PHONY: iac-clean
iac-clean: ## Clean the local terraform infrastructure
	@echo "[$@] :: cleaning the infrastructure intermediary files"
	@rm -fr $(TF_PLAN) $(TF_VARS);
	@if [ ! -f $(IAC_DIR).iac-env ] || [ $$(cat $(IAC_DIR).iac-env || echo -n) != $(PROJECT_ID) ]; then \
		echo "[$@] :: env has changed, removing also $(TF_DIR) and $(IAC_DIR).terraform.lock.hcl"; \
		rm -rf $(TF_DIR) $(IAC_DIR).terraform.lock.hcl; \
	fi;

	@echo "[$@] :: infrastructure cleaning DONE"

# -- this target will initialize the terraform initialization
.PHONY: iac-init
iac-init: $(TF_INIT) ## Procede to the terraform initialization
$(TF_INIT):
	@set -euo pipefail; \
	if [ ! -d $(TF_DIR) ]; then \
		function remove_me() { if (( $$? != 0 )); then rm -fr $(TF_DIR); fi; }; \
		trap remove_me EXIT; \
		echo "[iac-init] :: initializing terraform"; \
		echo "$(PROJECT_ID)" > $(IAC_DIR).iac-env; \
		cd $(IAC_DIR) && terraform init \
			-backend-config=bucket=$(DEPLOY_BUCKET) \
			-backend-config=prefix=terraform-state/$(ENV) \
			-input=false; \
	else \
		echo "[iac-init] :: terraform already initialized"; \
	fi;

# -- internal definition for easing changes
define HERE_TF_VARS
project             = "$(PROJECT_ID)"
zone                = "$(ZONE)"
region              = "$(REGION)"
env       		    = "$(ENV)"
repository_id		= "$(REPOSITORY_ID)"
github_owner        = "$(GITHUB_OWNER)"
github_repo         = "$(GITHUB_REPO)"
github_token        = "$(GITHUB_TOKEN)"
pypi_token          = "$(PYPI_TOKEN)"
codecov_token       = "$(CODECOV_TOKEN)"
endef
export HERE_TF_VARS

# -- this target will create the terraform.tfvars file
.PHONY: iac-prepare
iac-prepare: $(TF_VARS) ## Prepares the terraform infrastructure by create the variable files
$(TF_VARS): $(TF_INIT)
	@echo "[iac-prepare] :: generation of $(TF_VARS) file";
	@echo "$$HERE_TF_VARS" > $(TF_VARS);
	@echo "[iac-prepare] :: generation of $(TF_VARS) file DONE.";

# -- this target will create the tfplan file whenever the variables file and any *.tf
# file have changed
.PHONY: iac-plan
iac-plan-clean:
	@rm -f $(TF_PLAN)

iac-plan: iac-plan-clean $(TF_PLAN) ## Produce the terraform plan to visualize what will be changed in the infrastructure
$(TF_PLAN): $(TF_VARS) $(TF_FILES)
	@echo "[iac-plan] :: planning the iac in $(PROJECT_ID)";
	@set -euo pipefail; \
	cd $(IAC_DIR) && terraform plan \
		-var-file $(shell basename $(TF_VARS)) \
		-out=$(shell basename $(TF_PLAN));
	@echo "[iac-plan] :: planning the iac for $(PROJECT_ID) DONE.";

.PHONY: iac-validate
iac-validate: ## Validate the infrastructure
	@echo "[$@] :: validating the infrastructure for $(PROJECT_ID)"
	@set -euo pipefail; \
	cd $(IAC_DIR) && terraform validate;
	@echo "[$@] :: infrastructure validated on $(PROJECT_ID)"

.PHONY: iac-sec
iac-sec: ## Check the security of the infrastructure
	@echo "[$@] :: checking the infrastructure security for $(PROJECT_ID)"
	@tfsec .
	@echo "[$@] :: security checked on $(PROJECT_ID)"

.PHONY: iac-version
iac-version: ## Check the terraform version
	@cd $(IAC_DIR) && terraform -version

.PHONY: iac-deploy
iac-deploy: iac-clean $(TF_PLAN) ## Proceeds to the application of the terraform infrastructure
	@echo "[$@] :: applying the infrastructure for $(PROJECT_ID)"
	@set -euo pipefail; \
	cd $(IAC_DIR) && terraform apply -auto-approve -input=false $(shell basename $(TF_PLAN));
	@echo "[$@] :: infrastructure applied on $(PROJECT_ID)"

.PHONY: reinit
reinit: ## Remove untracked files from the current git repository
	@rm -rf $(IAC_DIR).terraform* $(IAC_DIR)terraform.tfstate* $(IAC_DIR)tfplan
