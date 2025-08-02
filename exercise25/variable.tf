variable "hcloud_token" {
  type        = string
  description = "Hetzner Cloud API token"
}

variable "privateSubnet" {
  type = object({
    dnsDomainName = string
    ipAndNetmask  = string
  })
}

