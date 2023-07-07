include {
  path = find_in_parent_folders()
}

locals {
  common_vars = yamldecode(file("${find_in_parent_folders("common_vars.yaml")}"))
}

terraform {
  source = "../../../blueprints/shared-vpc"
}

inputs = {
  env_abbr = local.common_vars.env_abbr
  lb_billing_account = local.common_vars.lb_billing_account
  default_region = local.common_vars.default_region
  proj_default_parent_folder = local.common_vars.proj_default_parent_folder
  tf_sa_email = local.common_vars.tf_sa_email
  goo_iap_ranges = local.common_vars.goo_iap_ranges

  lb-subnets = [
  {
    "description" = "Subnet HVN in CongDev"
    "subnet_flow_logs" = "false"
    "subnet_flow_logs_interval" = "INTERVAL_10_MIN"
    "subnet_flow_logs_metadata" = "INCLUDE_ALL_METADATA"
    "subnet_flow_logs_sampling" = 0.1
    "subnet_ip" = "10.110.1.0/24"
    "subnet_name" = "subnet-hvn"
    "subnet_private_access" = "true"
    "subnet_region"         = local.common_vars.default_region

  },
  ]

  subnet-hvn = [
    {
      range_name    = "ai-notebooks"
      ip_cidr_range = "10.110.2.0/24"
    },
  ],
}
