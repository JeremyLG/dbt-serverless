locals {
  dbt_roles = toset(["bigquery.dataEditor", "bigquery.user"])
}
resource "google_service_account" "dbt_sa" {
  account_id   = "dbt-runner"
  project      = var.project
  display_name = "dbt Service Account"
  description  = "dbt service account"
}

resource "google_project_iam_member" "sa_iam_dbt" {
  for_each = local.dbt_roles
  project  = var.project
  role     = "roles/${each.key}"
  member   = "serviceAccount:${google_service_account.dbt_sa.email}"
}

resource "google_cloud_run_service" "dbt_serverless" {
  provider = google-beta
  project  = var.project
  location = var.region
  name     = "dbt-serverless"

  template {
    metadata {
      annotations = {
        "run.googleapis.com/execution-environment" : "gen2"
      }
    }
    spec {
      containers {
        image = "${var.region}-docker.pkg.dev/${var.project}/${var.repository_id}/dbt-serverless:latest"
        env {
          name = "GOOGLE_CLOUD_PROJECT"
          value = var.project
        }
        resources {
          limits = {
            "cpu"  = "1000m"
            memory = "2048Mi"
          }
        }
      }
      service_account_name = google_service_account.dbt_sa.email
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

output "dbt_serverless_url" {
  value = google_cloud_run_service.dbt_serverless.status[0].url
}
