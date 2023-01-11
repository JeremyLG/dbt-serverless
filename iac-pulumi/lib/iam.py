import pulumi_gcp as gcp

from .service_account import dbt_sa, github_actions_sa
from .variables import variables as var


class FileError(Exception):
    pass


def read_file(path: str) -> list[str]:
    try:
        with open(path, "r") as f:
            return f.read().splitlines()
    except (FileNotFoundError, PermissionError):
        raise FileError(f"Failed to read file: {path}")


dbt_roles = ["bigquery.admin", "storage.admin"]
cicd_roles = read_file("iac-pulumi/resources/cicd.txt")
sa_iam_dbt = [
    gcp.projects.IAMMember(
        f"dbt-iam-member-{role}",
        project=var.project,
        role=f"roles/{role}",
        member=dbt_sa.email.apply(lambda email: f"serviceAccount:{email}"),
    )
    for role in dbt_roles
]
sa_iam_cicd = [
    gcp.projects.IAMMember(
        f"cicd-iam-member-{role}",
        project=var.project,
        role=f"roles/{role}",
        member=github_actions_sa.email.apply(lambda email: f"serviceAccount:{email}"),
    )
    for role in cicd_roles
]
