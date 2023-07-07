terraform {}

resource "random_id" "chars" {
  byte_length = 2
}

data "terraform_remote_state" "shared-vpc" {
    backend = "gcs"
    config = {
        prefix = "shared-vpc"
        bucket = var.lb-tf-bucket
    }
}

data "terraform_remote_state" "thehub" {
    backend = "gcs"
    config = {
        prefix = "thehub"
        bucket = var.lb-tf-bucket
    }
}

locals {
  proj_vpc_id = data.terraform_remote_state.shared-vpc.outputs.proj_sharedvpc_id
  vpc_networks = data.terraform_remote_state.shared-vpc.outputs.vpc_network
  thehubstorage = data.terraform_remote_state.thehub.outputs.thehubstorage
  proj_thehub_id = data.terraform_remote_state.thehub.outputs.project_id
  random_id = random_id.chars.hex
  proj_personal_number = google_project.personal.number
  vpc_subnets = data.terraform_remote_state.shared-vpc.outputs.vpc_subnets
}

resource "google_project" "personal" {
  name = "lb-${var.env_abbr}-${var.username}"
  project_id = "lb-${var.env_abbr}-${var.username}-${local.random_id}"
  folder_id  = var.proj_default_parent_folder
  billing_account = var.lb_billing_account
  auto_create_network = false
}

module "project-services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "14.2"
  project_id                  = google_project.personal.id

  activate_apis = [
    "compute.googleapis.com",
    "iam.googleapis.com",
    "iap.googleapis.com",
    "cloudbilling.googleapis.com",
    "serviceusage.googleapis.com",
    "bigquery.googleapis.com",
    "bigquerydatatransfer.googleapis.com",
    "monitoring.googleapis.com",
    "notebooks.googleapis.com"
  ]
 
  depends_on = [ 
    google_project.personal
  ]
}

## Connect to Host Project to get Networking
resource "google_compute_shared_vpc_service_project" "personal" {
  host_project = local.proj_vpc_id
  service_project = google_project.personal.project_id
  depends_on = [module.project-services]

}

## Enable Quotas
resource "google_service_usage_consumer_quota_override" "bigquery_daily_usage" {
  provider       = google-beta
  project        = google_project.personal.project_id
  service        = "bigquery.googleapis.com"
  metric         = "bigquery.googleapis.com%2Fquota%2Fquery%2Fusage"
  limit          = "%2Fd%2Fproject"
  override_value = coalesce(var.bq_quota_daily_usage, "52428800") #in MB - Default: 50TB
  force          = true
}

resource "google_project_iam_member" "proj_viewer" {
  project        = google_project.personal.project_id
  role    = "roles/viewer"
  member  = "user:${var.user_email}"
}

resource "google_project_iam_member" "gcs_objects" {
  project        = google_project.personal.project_id
  role    = "roles/storage.objectAdmin"
  member  = "user:${var.user_email}"

}

resource "google_project_iam_member" "bq_admin" {
  project        = google_project.personal.project_id
  role    = "roles/bigquery.admin"
  member  = "user:${var.user_email}"
}

resource "google_service_account" "user_default_sa" {
  project        = google_project.personal.project_id
  account_id   = "${var.username}-sa"
  display_name = "SA for personal project"
}

resource "google_service_account_iam_member" "user_own_sa" {
  service_account_id = google_service_account.user_default_sa.id
  role               = "roles/iam.serviceAccountUser"
  member  = "user:${var.user_email}"
}

## Creating GCS bucket for each user
resource "google_storage_bucket" "personal" {
  project        = google_project.personal.project_id
  name          = "lb-${var.env_abbr}-${var.username}-${local.random_id}"
  location      = var.default_region
  force_destroy = true
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_iam_member" "sa_data" {
  bucket = google_storage_bucket.personal.name
  role = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.user_default_sa.email}"
}

resource "google_project_iam_member" "user_sa_thehub_buckets" {
  project        = local.proj_thehub_id
  role = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.user_default_sa.email}"
}

resource "google_storage_bucket_iam_member" "user_data" {
  bucket = google_storage_bucket.personal.name
  role = "roles/storage.admin"
  member  = "user:${var.user_email}"

}

## Read post-provision script on thehubstorage bucket
resource "google_storage_bucket_iam_member" "thehubstorage" {
  bucket = local.thehubstorage
  role = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.user_default_sa.email}"
}

resource "google_project_iam_member" "sa_bqadmin" {
  project        = google_project.personal.project_id
  role    = "roles/bigquery.admin"
  member = "serviceAccount:${google_service_account.user_default_sa.email}"
}

resource "google_project_iam_custom_role" "user_custom_role" {
  project        = google_project.personal.project_id
  role_id     = "lb_user_role"
  description  = "Custom Role for personal project"
  title = "lb_user_role"
  permissions = [
    "notebooks.instances.reset", #Reset notebook instance
    "notebooks.instances.stop",
    "notebooks.instances.start",
    "compute.instances.stop",
    "compute.instances.start",
    "compute.instances.resume",
    "compute.instances.setLabels"
  ]
}

resource "google_project_iam_member" "user_custom_role" {
  project        = google_project.personal.project_id
  role = google_project_iam_custom_role.user_custom_role.name
  member  = "user:${var.user_email}"


}

resource "google_project_iam_member" "user_default_sa_custom_role" {
  project        = google_project.personal.project_id
  role = google_project_iam_custom_role.user_custom_role.name
  member = "serviceAccount:${google_service_account.user_default_sa.email}"

}

variable "lb_collaborators" {
  type = list
  default = []  
}

## Allow internal teams to access to BQ  on this personal project
resource "google_project_iam_member" "lb_user_bigquery_admin" {
  for_each = toset(var.lb_collaborators)
  project        = google_project.personal.project_id
  role    = "roles/bigquery.admin"
  member = each.value
}

resource "google_project_iam_member" "lb_user_viewer" {
  for_each = toset(var.lb_collaborators)
  project        = google_project.personal.project_id
  role    = "roles/viewer"
  member = each.value
}

resource "google_project_iam_member" "lb_user_gcs" {
  for_each = toset(var.lb_collaborators)
  project        = google_project.personal.project_id
  role    = "roles/storage.objectAdmin"
  member = each.value
}
