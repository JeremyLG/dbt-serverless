terraform {
  required_version = "~> 1.3.7"
  backend "gcs" {}
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 4.47.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 4.47.0"
    }
  }
}
