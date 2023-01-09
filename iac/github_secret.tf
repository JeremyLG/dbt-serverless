resource "github_actions_secret" "example_secret" {
  repository      = var.github_repo
  secret_name     = "ENV_FILE"
  plaintext_value = file("../.env")
}

resource "github_actions_secret" "project" {
  repository      = var.github_repo
  secret_name     = "PROJECT"
  plaintext_value = var.project
}

resource "github_actions_secret" "project_id" {
  repository      = var.github_repo
  secret_name     = "PROJECT_ID"
  plaintext_value = data.google_project.dbt-serverless.number
}

resource "github_actions_secret" "pypi_token" {
  repository      = var.github_repo
  secret_name     = "PYPI_TOKEN"
  plaintext_value = var.pypi_token
}

resource "github_actions_secret" "codecov_token" {
  repository      = var.github_repo
  secret_name     = "CODECOV_TOKEN"
  plaintext_value = var.codecov_token
}
