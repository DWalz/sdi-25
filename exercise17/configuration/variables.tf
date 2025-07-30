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
