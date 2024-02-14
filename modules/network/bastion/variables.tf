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

variable "subnet_id" {
  type = string
}

variable "sku" {
  type    = string
  default = "Basic"
}


variable "log_analytics_workspace_id" {
  type     = string
  default  = ""
  nullable = false
}