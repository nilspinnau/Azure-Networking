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

variable "inbound_subnet_id" {
  type     = string
  nullable = true
}

variable "outbound_subnet_id" {
  type     = string
  nullable = false
}

variable "vnet_id" {
  type     = string
  nullable = false
}

variable "forwarding_rules" {
  type = list(object({
    rule_name   = string
    domain_name = string
    dns_servers = list(object({
      ip_address = string
      port       = optional(number, 53)
    }))
  }))
  default  = []
  nullable = false
}
