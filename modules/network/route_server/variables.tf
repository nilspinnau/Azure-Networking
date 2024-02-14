variable "az_region" {
  type = string
}

variable "resource_postfix" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "enable_branch_to_branch_traffic" {
  type    = bool
  default = true
}

variable "subnet_id" {
  type = string
}