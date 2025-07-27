terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
  }
  required_version = ">= 0.13"
}

variable "hcloud_api_token" {
  description = "API token for the Hetzner Cloud"
  type        = string
  sensitive   = true
}

provider "hcloud" {
  token = var.hcloud_api_token
}

resource "hcloud_firewall" "fw_exercise_12" {
  name = "exercise-12-fw"
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

resource "hcloud_ssh_key" "dw084_ssh_key" {
  name       = "dw084-ssh-key"
  public_key = file("../ssh_key_dw084.pub")
}

resource "hcloud_server" "exercise_12" {
  name         = "exercise-12"
  image        = "debian-12"
  server_type  = "cx22"
  firewall_ids = [hcloud_firewall.fw_exercise_12.id]
  ssh_keys     = [hcloud_ssh_key.dw084_ssh_key.id]
  user_data    = file("install_nginx.sh")
}
