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


variable "vm_backend_configs" {
  type = list(object({
    vm_id                     = string
    nic_id                    = string
    nic_ip_configuration_name = string
  }))
}
