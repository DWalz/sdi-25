variable "hcloud_api_token" {
  description = "API token for the Hetzner Cloud"
  type        = string
  sensitive   = true
}

variable "server_username" {
  description = "Username to use for the default user on the server"
  type        = string
  default     = "devops"
}

variable "volume_mount" {
  description = "Mounting point of the volume in the root file system"
  type        = string
  default     = "volume01"
}

variable "location" {
  description = "Hetzner datacenter location to create the main resources in"
  type        = string
  default     = "hel1"
  validation {
    condition     = contains(["fsn1", "nbg1", "hel1", "ash", "hil", "sin"], var.location)
    error_message = "The location must be a valid datacenter"
  }
}

variable "server_count" {
  description = "Amount of servers to deploy"
  type        = number
  default     = 1
  validation {
    condition     = var.server_count > 0
    error_message = "There must be at least one server"
  }
}

variable "dns_secret_key" {
  description = "Secret Key for the DNS nameserver"
  type        = string
  sensitive   = true
}

variable "dns_server_domain" {
  description = "The base domain of the servers"
  type        = string
  default     = "g2.sdi.hdm-stuttgart.cloud"
}

variable "dns_server_name" {
  description = "The base name of the servers; will be extended with `-i` for the i-th server"
  type        = string
}

variable "dns_server_aliases" {
  description = "Alias names of the servers"
  type        = set(string)
  default     = []
  validation {
    condition     = !contains(var.dns_server_aliases, var.dns_server_name)
    error_message = "Alias may not shadow the main name"
  }
}
