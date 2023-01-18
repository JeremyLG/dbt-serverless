SHELL := /bin/bash

include .env
include includes/python.mk
include includes/terraform.mk

PROJECT_ID=$(PROJECT)-$(ENV)
GOOGLE_CLOUD_PROJECT=$(PROJECT_ID)

.EXPORT_ALL_VARIABLES:
.DEFAULT_GOAL := help

.PHONY: all test check quality run docker


# -- bucket definitions
DEPLOY_BUCKET   := $(PROJECT_ID)-gcs-deploy

docker-build:
	@docker build --tag dbt-serverless .

docker-run:
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

help: ## Displays the current message
	@awk -F ':.*?##' '/^[^\t].+?:.*?.*?##/ {printf "\033[36m%-30s\033[0m %s\n", $$1, $$NF}' $(MAKEFILE_LIST)

all: create-project create-bucket create-artifactregistry build deploy-app

build: check build-app
deploy: deploy-app iac-clean iac-deploy

gcloud:
	gcloud projects add-iam-policy-binding $(PROJECT_ID) \
		--member=user:$(ACCOUNT) \
		--role=roles/iam.serviceAccountTokenCreator

gcloud-auth:
	@gcloud auth print-access-token --project $(PROJECT)

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
