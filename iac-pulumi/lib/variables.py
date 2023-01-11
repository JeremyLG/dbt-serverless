from os import environ


class Variables:
    # pulumi
    project_name: str = environ.get("PROJECT")
    stack_name = "dev"

    # gcp
    project: str = environ.get("PROJECT_ID")
    region: str = environ.get("REGION")
    zone: str = environ.get("ZONE")

    # github
    github_owner: str = environ.get("GITHUB_OWNER")
    github_repo: str = environ.get("GITHUB_REPO")
    github_token: str = environ.get("GITHUB_TOKEN")

    # others
    pypi_token: str = environ.get("PYPI_TOKEN")
    codecov_token: str = environ.get("CODECOV_TOKEN")


variables = Variables()
