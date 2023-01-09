provider "google-beta" {
  project = var.project
  region  = var.region
  zone    = var.zone
  #   impersonate_service_account = "github-actions@geeeenre.iam.gserviceaccount.com"
}

provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
  #   impersonate_service_account = "github-actions@geeeenre.iam.gserviceaccount.com"
}

# Configure the GitHub Provider
provider "github" {
  token = var.github_token
  owner = var.github_owner
}
