variable "az_region" {
  type = string
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group in which to deploy the network security group into."
}

variable "resource_postfix" {
  type = string
}


variable "enable_flow_log" {
  type    = bool
  default = false
}

variable "enable_log_analytics" {
  type    = bool
  default = true
}
