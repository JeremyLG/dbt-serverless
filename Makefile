SHELL := /bin/bash

include .env

PROJECT_ID=$(PROJECT)-$(ENV)
GOOGLE_CLOUD_PROJECT=$(PROJECT_ID)

.EXPORT_ALL_VARIABLES:
.PHONY: all test


# -- bucket definitions
DEPLOY_BUCKET   := $(PROJECT_ID)-gcs-deploy

check: poetry-lock quality test

test: prepare-test poetry-test

quality: prepare-quality poetry-quality

prepare-quality:
	@poetry install --only nox,fmt,lint,type_check,docs

poetry-quality:
	@poetry run nox -s fmt_check
	@poetry run nox -s lint
	@poetry run nox -s type_check
	@poetry run nox -s docs

poetry-lock:
	@poetry lock --check

prepare-test:
	@poetry install --only nox

poetry-test:
	@poetry run nox -s test-3.9
	@poetry run nox -s test-3.10

clean-code:
	@poetry run isort .
	@poetry run black .

local-test: local-build local-run

local-build:
	@docker build --tag dbt-serverless .

local-run:
	@docker run \
		--rm \
		--interactive \
		--tty \
		-p 8080:8080 \
		-v "$(HOME)/.config/gcloud:/gcp/config:ro" \
		-v /gcp/config/logs \
		--env CLOUDSDK_CONFIG=/gcp/config \
		--env GOOGLE_APPLICATION_CREDENTIALS=/gcp/config/application_default_credentials.json \
		--env GOOGLE_CLOUD_PROJECT=$(PROJECT_ID) \
		--env DBT_PROJECT=$(DBT_PROJECT) \
		--env DBT_DATASET=$(DBT_DATASET) \
		--env DBT_PROFILES_DIR=$(DBT_PROJECT) \
		dbt-serverless
	@docker rmi -f $$(docker images -f "dangling=true" -q)
	@docker volume prune -f

# ---------------------------------------------------------------------------------------- #
# This target will perform the complete setup of the current repository.
# ---------------------------------------------------------------------------------------- #

all: create-project create-bucket create-artifactregistry build deploy

build: test build-app

deploy: deploy-app iac-clean iac-deploy

gcloud:
	gcloud projects add-iam-policy-binding $(PROJECT_ID) \
		--member=user:$(ACCOUNT) \
		--role=roles/iam.serviceAccountTokenCreator

# -- This target triggers the creation of the necessary project
.PHONY: create-project
create-project:
	@echo "[$@] :: creating project..."
	@echo "$(PROJECT_ID)"
	@gcloud projects create $(PROJECT_ID) --name=$(PROJECT_ID) --organization=$(ORG_ID) --folder=$(FOLDER_ID)
	@echo "[$@] :: linking billing account to project..."
	@gcloud beta billing projects link $(PROJECT_ID) --billing-account=$(BILLING_ID)
	@echo "[$@] :: project creation is over."

create-artifactregistry:
	@echo "[$@] :: enabling apis..."
	@gcloud services enable artifactregistry.googleapis.com --project $(PROJECT_ID)
	@echo "[$@] :: letting apis activation propagate... 30secs"
	@timeout 30
	@echo "[$@] :: creating repository..."
	@gcloud artifacts repositories create $(REPOSITORY_ID) \
		--project $(PROJECT_ID) \
		--location $(REGION) \
		--repository-format docker \
		--description "Docker repository"
	@echo "[$@] :: apis enabled"

# -- This target triggers the creation of the necessary buckets
.PHONY: create-bucket
create-bucket:
	@echo "[$@] :: creating bucket..."
	@gsutil ls -p $(PROJECT_ID) gs://$(DEPLOY_BUCKET) 2>/dev/null || \
		gsutil mb -l EU -p $(PROJECT_ID) gs://$(DEPLOY_BUCKET);
	@gsutil versioning set on gs://$(DEPLOY_BUCKET);
	@echo "[$@] :: bucket creation is over."

# -- This target triggers the deletion of the gcloud project
.PHONY: delete-project
delete-project:
	@echo "[$@] :: deleting project..."
	@gcloud beta billing projects unlink $(PROJECT_ID)
	@gcloud projects delete $(PROJECT_ID)
	@echo "[$@] :: deletion is over."

.PHONY: clean
clean: iac-clean

# ---------------------------------------------------------------------------------------- #
# -- < Building > --
# ---------------------------------------------------------------------------------------- #

build-app:
	@echo "[$@] :: building the Docker image"
	@set -euo pipefail; \
	docker build \
		--tag $(REGION)-docker.pkg.dev/$(PROJECT_ID)/$(REPOSITORY_ID)/dbt-serverless:latest \
		.
	@echo "[$@] :: docker build is over."

deploy-app:
	@echo "[$@] :: Pushing docker image"
	@docker push $(REGION)-docker.pkg.dev/$(PROJECT_ID)/$(REPOSITORY_ID)/dbt-serverless:latest;
	@echo "[$@] :: docker push is over."

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

# -- this target will clean the local terraform infrastructure
.PHONY: iac-clean
iac-clean:
	@echo "[$@] :: cleaning the infrastructure intermediary files"
	@rm -fr $(TF_PLAN) $(TF_VARS);
	@if [ ! -f $(IAC_DIR).iac-env ] || [ $$(cat $(IAC_DIR).iac-env || echo -n) != $(PROJECT_ID) ]; then \
		echo "[$@] :: env has changed, removing also $(TF_DIR) and $(IAC_DIR).terraform.lock.hcl"; \
		rm -rf $(TF_DIR) $(IAC_DIR).terraform.lock.hcl; \
	fi;

	@echo "[$@] :: infrastructure cleaning DONE"

# -- this target will initialize the terraform initialization
.PHONY: iac-init
iac-init: $(TF_INIT) # provided for convenience
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
iac-prepare: $(TF_VARS) # provided for convenience
$(TF_VARS): $(TF_INIT)
	@echo "[iac-prepare] :: generation of $(TF_VARS) file";
	@echo "$$HERE_TF_VARS" > $(TF_VARS);
	@echo "[iac-prepare] :: generation of $(TF_VARS) file DONE.";

# -- this target will create the tfplan file whenever the variables file and any *.tf
# file have changed
.PHONY: iac-plan iac-plan-clean
iac-plan-clean:
	@rm -f $(TF_PLAN)

iac-plan: iac-plan-clean $(TF_PLAN) # provided for convenience
$(TF_PLAN): $(TF_VARS) $(TF_FILES)
	@echo "[iac-plan] :: planning the iac in $(PROJECT_ID)";
	@set -euo pipefail; \
	cd $(IAC_DIR) && terraform plan \
		-var-file $(shell basename $(TF_VARS)) \
		-out=$(shell basename $(TF_PLAN));
	@echo "[iac-plan] :: planning the iac for $(PROJECT_ID) DONE.";

# -- this target will only trigger the iac of the current parent
.PHONY: iac-validate
iac-validate:
	@echo "[$@] :: validating the infrastructure for $(PROJECT_ID)"
	@set -euo pipefail; \
	cd $(IAC_DIR) && terraform validate;
	@echo "[$@] :: infrastructure validated on $(PROJECT_ID)"

# -- this target will only trigger the iac of the current parent
.PHONY: iac-sec
iac-sec:
	@echo "[$@] :: checking the infrastructure security for $(PROJECT_ID)"
	@tfsec .
	@echo "[$@] :: security checked on $(PROJECT_ID)"

# -- this target will only trigger the iac of the current parent
.PHONY: iac-version
iac-version:
	@cd $(IAC_DIR) && terraform -version

# -- this target will only trigger the iac of the current parent
.PHONY: iac-deploy
iac-deploy: iac-clean $(TF_PLAN)
	@echo "[$@] :: applying the infrastructure for $(PROJECT_ID)"
	@set -euo pipefail; \
	cd $(IAC_DIR) && terraform apply -auto-approve -input=false $(shell basename $(TF_PLAN));
	@echo "[$@] :: infrastructure applied on $(PROJECT_ID)"

# -- this target re-initializes the git working tree removing untracked and ignored files
.PHONY: reinit
reinit:
	@rm -rf $(IAC_DIR).terraform* $(IAC_DIR)terraform.tfstate* $(IAC_DIR)tfplan
