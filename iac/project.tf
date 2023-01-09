data "google_project" "dbt-serverless" {
}

output "project_number" {
  value = data.google_project.dbt-serverless.number
}
