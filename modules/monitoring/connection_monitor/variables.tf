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


variable "endpoints" {
  type = list(object({
    name        = string
    resource_id = optional(string, null)
    ip_address  = optional(string, null)
  }))
}

variable "test_configurations" {
  type = list(object({
    name                      = string
    protocol                  = optional(string, "Tcp")
    test_frequency_in_seconds = optional(number, 60)
  }))
}

variable "test_groups" {
  type = list(object({
    name                     = string
    sources                  = list(string)
    destinations             = list(string)
    test_configuration_names = list(string)
  }))
}
