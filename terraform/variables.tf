
variable "region" {
  type    = string
  default = "sa-east-1"
}

variable "kinesis_name" {
  type    = string
  default = "marketing-events"
}

variable "s3_bucket" {
  type    = string
  description = "Bucket for Glue staging and scripts"
}

variable "rs_namespace" {
  type    = string
  default = "marketing-ns"
}

variable "rs_workgroup" {
  type    = string
  default = "marketing-wg"
}

variable "rs_admin_user" {
  type    = string
  default = "adminuser"
}

variable "rs_admin_password" {
  type    = string
  description = "Redshift admin password - override in tfvars or CI secrets"
  type = string
  default = "ChangeMe123!"
}

variable "rs_capacity" {
  type    = number
  default = 32
}
