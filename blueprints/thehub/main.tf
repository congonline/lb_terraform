terraform {}

data "terraform_remote_state" "shared-vpc" {
    backend = "gcs"
    config = {
        prefix = "shared-vpc"
        bucket = var.lb-tf-bucket
    }
}

resource "random_id" "proj_id_suff" {
  byte_length = 2
}

locals {
  proj_vpc_id = data.terraform_remote_state.shared-vpc.outputs.proj_sharedvpc_id
  vpc_networks = data.terraform_remote_state.shared-vpc.outputs.vpc_network

  random_id = random_id.proj_id_suff.hex
}

resource "google_project" "thehub" {
  name = "lb-${var.env_abbr}-thehub"
  project_id = "lb-${var.env_abbr}-thehub-${local.random_id}"
  folder_id  = var.proj_default_parent_folder
  billing_account = var.lb_billing_account
  auto_create_network = false
}

module "project-services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "14.2"
  project_id                  = google_project.thehub.id

  activate_apis = [
    "orgpolicy.googleapis.com",
    "compute.googleapis.com",
    "iam.googleapis.com",
    "cloudbilling.googleapis.com",
    "serviceusage.googleapis.com",
    "bigquery.googleapis.com",
    "bigquerydatatransfer.googleapis.com",
    "servicenetworking.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "logging.googleapis.com",
  ]
}

## Connect to Host Project to get Networking
resource "google_compute_shared_vpc_service_project" "thehub" {
  host_project = local.proj_vpc_id
  service_project = google_project.thehub.project_id
  depends_on = [module.project-services]

}

