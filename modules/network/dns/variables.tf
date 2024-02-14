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

variable "dns_zones" {
  type = list(object({
    name                     = string
    enable_auto_registration = bool
  }))
}

variable "vnet" {
  type = object({
    id   = string
    name = string
  })
}
