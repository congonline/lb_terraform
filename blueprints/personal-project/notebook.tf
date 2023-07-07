resource "google_project_iam_member" "sa_notebook_access_vpc" {
  project = local.proj_vpc_id
  role    = "roles/compute.networkUser"
  member  = "serviceAccount:service-${local.proj_personal_number}@gcp-sa-notebooks.iam.gserviceaccount.com"
}

resource "google_notebooks_instance" "personal" {
  project = google_project.personal.project_id
  name = "lb-${var.env_abbr}-${var.username}-notebook"
  location = var.default_zone
  machine_type = var.notebook_configs["machine_type"]

  vm_image {
    project      = var.notebook_configs["project"]
    image_family = var.notebook_configs["image_family"]
  }

  metadata = {
    proxy-mode = "service_account"
  }

  service_account = google_service_account.user_default_sa.email

  boot_disk_type = "PD_SSD"
  boot_disk_size_gb = 110

  network = local.vpc_networks["network_id"]
  subnet = local.vpc_subnets["${var.default_region}/subnet-hvn"].id

  depends_on = [
    google_project_iam_member.sa_notebook_access_vpc
  ]
}

resource "google_service_account_iam_member" "notebook_admin" {
  for_each = toset(var.notebook_configs["notebook_admins"])
  service_account_id = google_service_account.user_default_sa.id
  role               = "roles/iam.serviceAccountUser"
  member  = "user:${each.value}"
}
