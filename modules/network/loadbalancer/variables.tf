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

variable "public_endpoint" {
  type     = bool
  default  = true
  nullable = false
}

variable "loadbalancing_rules" {
  type = list(object({
    name              = string
    backend_port      = number
    frontend_port     = number
    protocol          = string
    load_distribution = optional(string, "Default")
    floating_ip       = optional(bool, false)
    tcp_reset         = optional(bool, false)
  }))
  default = []
  validation {
    condition     = alltrue([for rule in var.loadbalancing_rules : contains(["Tcp", "Http", "Https"], rule.protocol)])
    error_message = "Possible values for protocol: 'Tcp', 'Http' and 'Https'"
  }
  nullable = false
}


variable "health_probe" {
  type = object({
    port     = number
    path     = string
    protocol = string
  })
  nullable = false
}

variable "vm_backend_configs" {
  type = list(object({
    vm_id                     = string
    nic_id                    = string
    nic_ip_configuration_name = string
  }))
}

variable "subnet_id" {
  type    = string
  default = null
}