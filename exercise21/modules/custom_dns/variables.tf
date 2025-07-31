variable "zone" {
  description = "The base domain for all DNS entries"
  type        = string
}

variable "main_name" {
  description = "The main server name"
  type        = string
}

variable "alias" {
  description = "The server's alias names"
  type        = set(string)
  default     = []
}

variable "server_ip" {
  description = "The IP address of the server"
  type        = string
}
