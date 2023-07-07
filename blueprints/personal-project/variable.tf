variable "bq_quota_daily_usage" {
  default = "52428800"
}

variable "proj_default_parent_folder" {
  default = ""
}

variable "env_abbr" { default = "" }

variable "lb_billing_account" { default = "" }

variable "lb-tf-bucket" {}

variable "username" {}
variable "user_email" {}

variable "default_zone" {}
variable "default_region" {}

variable "notebook_configs" {
  type = object({
    project = string
    machine_type = string
    image_family = string
    notebook_admins = list(string)
    })
}

