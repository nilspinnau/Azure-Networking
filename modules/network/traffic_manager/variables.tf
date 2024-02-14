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

variable "backends" {
  type = list(object({
    name      = string
    priority  = number
    target_id = string
  }))
}

variable "probe" {
  type = object({
    protocol = optional(string, "HTTP")
    port     = optional(number, 80)
    path     = optional(string, "/")
  })
  nullable = false
}