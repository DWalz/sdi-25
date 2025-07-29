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
