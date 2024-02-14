
variable "dns_forwarding_ruleset_id" {
  type = string
}

variable "dns_forwarding_ruleset_name" {
  type    = string
  default = "default"
}

variable "linked_vnets" {
  type = list(object({
    name : string
    id : string
  }))
}