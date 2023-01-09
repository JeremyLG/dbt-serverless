variable "project" {
  type        = string
  description = "Your project"
}

variable "region" {
  type        = string
  description = "The region where to deploy your infrastructure"
}

variable "zone" {
  type        = string
  description = "The zone where to deploy your infrastructure"
}

variable "repository_id" {
  type        = string
  description = "The artifact registry default docker repository"
}

variable "env" {
  type        = string
  description = "The project environment"
}

variable "github_owner" {
  type        = string
  description = "The github owner of your project"
}

variable "github_repo" {
  type        = string
  description = "The github repo of your project"
}

variable "github_token" {
  type        = string
  sensitive   = true
  description = "The github token of your project"
}

variable "pypi_token" {
  type        = string
  sensitive   = true
  description = "The pypi token of your project"
}

variable "codecov_token" {
  type        = string
  sensitive   = true
  description = "The codecov token of your project"
}
