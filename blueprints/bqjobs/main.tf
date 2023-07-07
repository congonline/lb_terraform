terraform {
}

resource "random_id" "no" {
  byte_length = 2
}
locals {
  id = random_id.no.hex

  proj_bqjobs = [
    "bqjob01",
    "bqjob02"
  ]
}

resource "google_project" "bqjob" {
  for_each = toset(local.proj_bqjobs)
  name       = "lb-${var.env_abbr}-${each.value}"
  project_id = "lb-${var.env_abbr}-${each.value}-${local.id}"
  folder_id  = var.proj_default_parent_folder
  billing_account = var.lb_billing_account
  auto_create_network = false
}

module "project-services" {
  for_each = toset(local.proj_bqjobs)
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "14.2"
  project_id = google_project.bqjob[each.value].id
  enable_apis = "true"
  disable_dependent_services   = "false"
  disable_services_on_destroy  = "false"

  activate_apis = [
    "cloudbilling.googleapis.com",
    "bigquery.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "stackdriver.googleapis.com",
    "bigquerydatatransfer.googleapis.com",
  ]
}

output "proj_bqjob_pool" {
  value = google_project.bqjob
}
