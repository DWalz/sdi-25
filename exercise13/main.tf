terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.51.0"
    }
  }
}

variable "hcloud_api_token" {
  description = "API token for the Hetzner Cloud"
  type        = string
  sensitive   = true
}

provider "hcloud" {
  token = var.hcloud_api_token
}

resource "hcloud_firewall" "fw_exercise_13" {
  name = "exercise-13-fw"
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

resource "hcloud_server" "exercise_13" {
  name        = "exercise-13"
  image       = "debian-12"
  server_type = "cpx11"
  user_data   = file("cloud_init.yml")
}

resource "hcloud_firewall_attachment" "exercise_fw_attachment" {
  firewall_id = hcloud_firewall.fw_exercise_13.id
  server_ids  = [hcloud_server.exercise_13.id]
  lifecycle {
    replace_triggered_by = [ hcloud_server.exercise_13, hcloud_firewall.fw_exercise_13 ]
  }
}
