include {
  path = find_in_parent_folders()
}

locals {
  common_vars = yamldecode(file("${find_in_parent_folders("common_vars.yaml")}"))
}

terraform {
  source = "../../../blueprints/personal-project"
}

inputs = {
  env_abbr = local.common_vars.env_abbr
  lb_billing_account = local.common_vars.lb_billing_account
  default_region = local.common_vars.default_region
  default_zone = local.common_vars.default_zone

  proj_default_parent_folder = local.common_vars.proj_default_parent_folder
  lb-tf-bucket = local.common_vars.lb-tf-bucket

  username = "daviduk"
  user_email = "oliverlenguyen@gmail.com"
  
  notebook_configs = {
    project = "deeplearning-platform-release"
    machine_type = "n2-standard-2"
    image_family = "common-cpu-notebooks"
    notebook_admins = [
      "congvihu@vihu.uk"
    ]
  }
}
