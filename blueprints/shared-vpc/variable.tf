variable "org_id" {
  default = ""
}

variable "default_region" {
  default = ""
}

variable "env_abbr" {
  default = ""
}

variable "proj_default_parent_folder" {
  default = ""
}

variable "lb_billing_account" {
  default = ""
}

variable "lb-subnets" {
  type = list
  default = [ ]
}

variable "subnet-hvn" {
  type = list
  default = [ ]
}

variable "goo_iap_ranges" {
  type = list
  default = ["10.0.0.1"]

}

variable "tf_sa_email" {}
