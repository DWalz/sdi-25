terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.51.0"
    }
  }
}

# Hetzner Cloud Provider Setup
variable "hcloud_api_token" {
  description = "API token for the Hetzner Cloud"
  type        = string
  sensitive   = true
}

provider "hcloud" {
  token = var.hcloud_api_token
}

# Variables
variable "server_username" {
  description = "Username to use for the default user on the server"
  type        = string
  default     = "devops"
}

# TLS Key
resource "tls_private_key" "server_ssh_key" {
  algorithm = "ED25519"
}

# Generated Files
resource "local_file" "cloud_init" {
  filename = "./gen/cloud_init.yml"
  content = templatefile("./template/cloud_init.yml", {
    default_user     = var.server_username
    local_ssh_public = file("~/.ssh/id_ed25519.pub")
    ssh_private      = tls_private_key.server_ssh_key.private_key_openssh
    ssh_public       = tls_private_key.server_ssh_key.public_key_openssh
  })
}

resource "local_file" "known_hosts" {
  filename        = "./gen/known_hosts"
  content         = join(" ", [hcloud_server.exercise_14.ipv4_address, tls_private_key.server_ssh_key.public_key_openssh])
  file_permission = "644"
}

resource "local_file" "ssh_bin" {
  filename = "./bin/ssh.sh"
  content = templatefile("./template/ssh.sh", {
    default_user = var.server_username
    ip           = hcloud_server.exercise_14.ipv4_address
  })
  file_permission = "755"
  depends_on      = [local_file.known_hosts]
}

resource "local_file" "scp_bin" {
  filename = "./bin/scp.sh"
  content = templatefile("./template/scp.sh", {
    default_user = var.server_username
    ip           = hcloud_server.exercise_14.ipv4_address
  })
  file_permission = "755"
  depends_on      = [local_file.known_hosts]
}

# Firewall & Server
resource "hcloud_firewall" "fw_exercise_14" {
  name = "exercise-14-fw"
  rule {
    description = "SSH inbound"
    direction   = "in"
    protocol    = "tcp"
    port        = 22
    source_ips  = ["0.0.0.0/0", "::/0"]
  }
  rule {
    description = "HTTP inbound"
    direction   = "in"
    protocol    = "tcp"
    port        = 80
    source_ips  = ["0.0.0.0/0", "::/0"]
  }
}

resource "hcloud_server" "exercise_14" {
  name        = "exercise-14"
  image       = "debian-12"
  server_type = "cpx11"
  user_data   = local_file.cloud_init.content
}

resource "hcloud_firewall_attachment" "exercise_fw_attachment" {
  firewall_id = hcloud_firewall.fw_exercise_14.id
  server_ids  = [hcloud_server.exercise_14.id]
  lifecycle {
    replace_triggered_by = [hcloud_server.exercise_14, hcloud_firewall.fw_exercise_14]
  }
}
