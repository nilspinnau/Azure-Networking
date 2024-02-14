variable "az_region" {
  type = string
}

variable "local_resource_group_name" {
  type        = string
  description = "Name of the resource group in which to deploy the network security group into."
}

variable "resource_postfix" {
  type = string
}

variable "connection" {
  type = object({
    name              = string
    enable_bgp        = optional(bool, false)
    shared_key        = string
    onprem_gateway_id = string
    azure_gateway_id  = string
  })
}

variable "remote_resource_group_name" {
  type = string
}
