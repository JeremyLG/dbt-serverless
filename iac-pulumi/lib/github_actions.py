import pulumi
import pulumi_gcp as gcp

from .service_account import github_actions_sa
from .variables import variables as var

pool = gcp.iam.WorkloadIdentityPool("github-pool", workload_identity_pool_id="github-pool-v2")
example = gcp.iam.WorkloadIdentityPoolProvider(
    "github",
    workload_identity_pool_id=pool.workload_identity_pool_id,
    workload_identity_pool_provider_id="github-provider",
    attribute_mapping={
        "google.subject": "assertion.sub",
        "attribute.actor": "assertion.actor",
        "attribute.aud": "assertion.aud",
        "attribute.repository": "assertion.repository",
    },
    oidc=gcp.iam.WorkloadIdentityPoolProviderOidcArgs(
        issuer_uri="https://token.actions.githubusercontent.com"
    ),
)
workload_identity_user = gcp.serviceaccount.IAMMember(
    "workloadIdentityUser",
    service_account_id=github_actions_sa.name,
    role="roles/iam.workloadIdentityUser",
    member=pool.name.apply(
        lambda name: "".join(
            [
                "principalSet://iam.googleapis.com/",
                name,
                "/attribute.repository/",
                var.github_owner,
                var.github_repo,
            ]
        )
    ),
)
pulumi.export(
    "workloadIdentityProvider",
    pulumi.Output.concat(pool.name, "/providers/", pool.workload_identity_pool_id),
)
