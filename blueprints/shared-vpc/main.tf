terraform {}

resource "random_id" "proj_id_suff" {
  byte_length = 2
}

locals {
  random_id = random_id.proj_id_suff.hex
  vpc_host_project_id = google_project.vpc_host_proj.project_id
  vpc_host_network_selflink = module.vpc.network.network_self_link
  tf_sa_parent_folder_permissions = [
    "roles/resourcemanager.projectCreator",
    "roles/compute.xpnAdmin" ##TODO: added to access sharedvpc networks
  ]
}

resource "google_folder_iam_member" "parent_folder" {
  for_each = toset(local.tf_sa_parent_folder_permissions)
  folder  = var.proj_default_parent_folder
  role    = each.value
  member  = "serviceAccount:${var.tf_sa_email}"
}

resource "google_project" "vpc_host_proj" {
  name       = "lb-${var.env_abbr}-sharedvpc"
  project_id = "lb-${var.env_abbr}-sharedvpc-${local.random_id}"
  folder_id  = var.proj_default_parent_folder
  billing_account = var.lb_billing_account
  auto_create_network = false

  depends_on = [
   google_folder_iam_member.parent_folder 
  ]
 }

module "project_services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "14.2"
  project_id = local.vpc_host_project_id
  enable_apis = "true"
  disable_dependent_services   = "false"
  disable_services_on_destroy  = "false"

  activate_apis = [
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "iam.googleapis.com",
    "stackdriver.googleapis.com",
    "cloudbilling.googleapis.com",
    "servicenetworking.googleapis.com",
  ]
  depends_on = [
    google_project.vpc_host_proj
  ]
}

module "vpc" {
    source  = "terraform-google-modules/network/google"
    version = "7.1" // TODO
    shared_vpc_host = true
    project_id   = local.vpc_host_project_id
    network_name = "lb-${var.env_abbr}-sharedvpc-${local.random_id}"
    routing_mode = "GLOBAL"
    subnets = [
      for subnet in var.lb-subnets:
        subnet
    ]
    secondary_ranges = {
        subnet-hvn = [
          for i in var.subnet-hvn:
            i
        ]
    }

  depends_on = [
    google_project.vpc_host_proj,
    module.project_services,
    google_folder_iam_member.parent_folder
  ]

}


## Creating NAT address
resource "google_compute_address" "lb-nat-address" {
  name   = "lb-${var.env_abbr}-nat-ext-address-${local.random_id}"
  region = var.default_region
  project = local.vpc_host_project_id
}

module "cloud-nat" {
  source     = "terraform-google-modules/cloud-nat/google"
  version    = "4.0.0"
  name       = "lb-${var.env_abbr}-cloudnat-${local.random_id}"
  project_id = local.vpc_host_project_id
  region     = var.default_region
  create_router = "true"
  router     = "lb-${var.env_abbr}-router-${local.random_id}"
  nat_ips       = google_compute_address.lb-nat-address.*.self_link
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  network    = local.vpc_host_network_selflink
}


resource "google_compute_firewall" "deny-all" {
  priority = 65534
  name = "logging-denied-all"
  project = local.vpc_host_project_id
  description = "This rule will deny all traffic and logs the activities"
  network    = local.vpc_host_network_selflink
  deny {
    protocol = "tcp"
  }
  source_ranges = ["0.0.0.0"]
  log_config  {
    metadata = "INCLUDE_ALL_METADATA"
  }

  depends_on = [
    module.vpc
  ]
}

resource "google_compute_firewall" "iap-ssh-server" {
  name    = "iap-to-ssh-server"
  project = local.vpc_host_project_id
  network = local.vpc_host_network_selflink

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags  = ["notebook-instance"]
  source_ranges = var.goo_iap_ranges

  depends_on = [
    module.vpc
  ]
}
