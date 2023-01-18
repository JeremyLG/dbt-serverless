# Serverless Endpoint for dbt runs


[![GitHub Actions][github-actions-badge]](https://github.com/JeremyLG/dbt-serverless/actions)
[![GitHub Actions][github-actions-terraform-badge]](https://github.com/JeremyLG/dbt-serverless/actions)
[![Packaged with Poetry][poetry-badge]](https://python-poetry.org/)
[![Code style: black][black-badge]](https://github.com/psf/black)
[![Imports: isort][isort-badge]](https://pycqa.github.io/isort/)
[![Type checked with mypy][mypy-badge]](https://github.com/python/mypy)
[![codecov][codecov-badge]](https://codecov.io/github/JeremyLG/dbt-serverless)

[![PyPI Latest Release](https://img.shields.io/pypi/v/dbt-serverless.svg)](https://pypi.org/project/dbt-serverless/)
[![Package Status](https://img.shields.io/pypi/status/dbt-serverless.svg)](https://pypi.org/project/dbt-serverless/)
[![License](https://img.shields.io/pypi/l/dbt-serverless.svg)](https://github.com/JeremyLG/dbt-serverless/blob/master/LICENSE.txt)

[github-actions-badge]: https://github.com/JeremyLG/dbt-serverless/actions/workflows/python.yml/badge.svg
[github-actions-terraform-badge]: https://github.com/JeremyLG/dbt-serverless/actions/workflows/terraform.yml/badge.svg
[black-badge]: https://img.shields.io/badge/code%20style-black-000000.svg
[isort-badge]: https://img.shields.io/badge/%20imports-isort-%231674b1?style=flat&labelColor=ef8336
[mypy-badge]: https://www.mypy-lang.org/static/mypy_badge.svg
[poetry-badge]: https://img.shields.io/badge/packaging-poetry-cyan.svg
[codecov-badge]: https://codecov.io/github/JeremyLG/dbt-serverless/branch/master/graph/badge.svg

The goal of this project is to avoid the need of an Airflow server in order to schedule dbt tasks like runs, snapshots, docs...

It currently encapsulate few dbt commands into a FastAPI server which can be deployed on Cloud Run in a serverless fashion. That way we reduce costs as Cloud Run is terribly cheap!

You can also test it locally or through Docker without it being serverless, but it doesn't make sense as you already have the dbt CLI for this.

## Usage

You'll need to make use of Google ADC (Authentification Default Credentials). Meaning either :
- gcloud cli already identified
- or a deployment through a google product with a service account having the roles/bigquery.admin
- or a GOOGLE_APPLICATION_CREDENTIALS env variable for a specific local keyfile 

### Local deployment

#### With pip

```bash
pip install dbt-serverless
python run uvicorn dbt_serverless.main:app --host 0.0.0.0 --port 8080 --reload
```

#### With poetry

```bash
poetry add dbt-serverless
poetry run uvicorn dbt_serverless.main:app --host 0.0.0.0 --port 8080 --reload
```


### Docker deployment
Simple docker image to build dbt-serverless for local or cloud run testing: [example Dockerfile](examples/Dockerfile.dbt).

If you're not on a Google product (like Cloud Run), you will need to specify google creds at docker runtime.

For example you can add these cli parameters at runtime, if you're testing and deploying it locally :
```bash
    -v "$(HOME)/.config/gcloud:/gcp/config:ro" \
    -v /gcp/config/logs \
    --env CLOUDSDK_CONFIG=/gcp/config \
    --env GOOGLE_APPLICATION_CREDENTIALS=/gcp/config/application_default_credentials.json \
    --env GOOGLE_CLOUD_PROJECT=$(YOUR_PROJECT_ID) \
```

