Dockerfiles, Terraform and Pulumi files to test and deploy your dbt-serverless in no time.

## Docker commands to test your own image and dbt project locally

In your project, you could use this `Dockerfile.dbt` file and with few environment variables set (see the `.env.template` file to fill your own `.env` file), you would only need to do the following :

```bash
export $(grep -v '^#' .env | xargs)
```

```bash
docker build . \
    -t $(DBT_PROJECT) \
    -f dbt.Dockerfile \
    --build-arg DBT_PROJECT=$(DBT_PROJECT) \
    --build-arg DBT_DATASET=$(DBT_DATASET) \
    --build-arg DBT_PROFILES_DIR=$(DBT_PROJECT)
```

```bash
docker run \
		--rm \
		--interactive \
		--tty \
		-p 8080:8080 \
		-v "$(HOME)/.config/gcloud:/gcp/config:ro" \
		-v /gcp/config/logs \
		--env CLOUDSDK_CONFIG=/gcp/config \
		--env GOOGLE_APPLICATION_CREDENTIALS=/gcp/config/application_default_credentials.json \
		--env GOOGLE_CLOUD_PROJECT=$(GOOGLE_CLOUD_PROJECT) \
		$(DBT_PROJECT)
```

## Deploy it on GCP

Here we provide a `main.tf` example to deploy your dbt-serverless in an already setup GCP Project with APIs enabled and a repository in Artifact Registry. You're just gonna need 3 terraform variables (but you might already use them in your project):
- var.project
- var.region
- var.repository_id

If it's not setup, you could just git clone the entire repository and use make commands to deploy the iac from scratch. In this case, look for the `.env.template` at the root directory and `make all`.

Anyway!

Build the image and tag it:

```bash
docker build . \
    -f Dockerfile.dbt \
    --tag $REGION-docker.pkg.dev/$GOOGLE_CLOUD_PROJECT/$REPOSITORY_ID/dbt-serverless:latest \
    --build-arg DBT_PROJECT=$DBT_PROJECT \
    --build-arg DBT_DATASET=$DBT_DATASET \
    --build-arg DBT_PROFILES_DIR=$DBT_PROJECT
```

Push it to Google Cloud Artifact Registry repository:

```bash
docker push $REGION-docker.pkg.dev/$GOOGLE_CLOUD_PROJECT/$REPOSITORY_ID/dbt-serverless:latest
```
