locals {
  common_vars = yamldecode(file("common_vars.yaml"))
}

remote_state {
  backend = "gcs"
  generate = {
    path      = "tf_backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    bucket = local.common_vars.lb-tf-bucket
    prefix = "${path_relative_to_include()}"
    project = local.common_vars.lb_tf_statefile_proj
    location = local.common_vars.default_region
  }
}

generate "provider" {
  path = "tf_provider.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
    terraform {
      required_providers {
        google = {
          version = "4.72.0"
        }
      }
    }
  EOF
}
