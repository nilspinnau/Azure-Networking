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

variable "enable_private_endpoint" {
  type     = bool
  default  = false
  nullable = false
}

variable "enable_service_endpoint" {
  type     = bool
  default  = false
  nullable = false
}

variable "enable_public_network_access" {
  type     = bool
  default  = true
  nullable = false
}

variable "containers_list" {
  type     = list(string)
  default  = ["container01"]
  nullable = false
}

variable "private_dns_zone_ids" {
  type     = list(string)
  nullable = false
  default  = []
}


variable "network_rules" {
  description = "Network rules restricing access to the storage account."
  type = object({
    default_action = optional(string, "Deny")
    bypass         = list(string)
    ip_rules       = list(string)
    subnet_ids     = list(string)
  })
  default = null
}
