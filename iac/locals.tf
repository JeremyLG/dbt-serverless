locals {
  services = toset(split("\n", trimspace(file("resources/services.txt"))))
  cicd_roles = toset(split("\n", trimspace(file("resources/cicd.txt"))))

  dbt_roles = toset([
    "bigquery.admin",
    "storage.admin"
  ])
}
