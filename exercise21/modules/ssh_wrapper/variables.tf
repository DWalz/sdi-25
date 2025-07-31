variable "server_username" {
  description = "Username to use for the default user on the server"
  type        = string
}

variable "server_hostname" {
  description = "Hostname to use for the default user on the server (e.g. IPv4)"
  type        = string
}

variable "server_public_key" {
  description = "The SSH public key of the server"
  type        = string
}

variable "output_dir" {
  description = "The output directory of the files; they will be generated under /gen and /bin inside this directory"
  type        = string
}
