import pulumi_gcp as gcp

from .variables import variables as var

# Github actions service account
github_actions_sa = gcp.serviceaccount.Account(
    "github-actions_sa",
    account_id="github-actions",
    project=var.project,
    display_name="CI/CD Service Account",
    description="CI/CD service account",
)

# Bigquery Owner
bigquery_owner = gcp.serviceaccount.Account(
    "bigquery-owner_sa", account_id="bigquery-owner", project=var.project
)
# dbt service account
dbt_sa = gcp.serviceaccount.Account(
    "dbt-runner_sa",
    account_id="dbt-runner",
    project=var.project,
    display_name="dbt Service Account",
    description="dbt service account",
)
# dbt service account key
dbt_sa_key = gcp.serviceaccount.Key(
    "dbt_sa_key", service_account_id=dbt_sa.name, public_key_type="TYPE_X509_PEM_FILE"
)
