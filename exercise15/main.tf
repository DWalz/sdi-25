terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.51.0"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_api_token
}

resource "hcloud_server" "exercise_15" {
  name        = "exercise-15"
  image       = "debian-12"
  server_type = "cpx11"
  user_data   = local_file.cloud_init.content
}

resource "hcloud_firewall_attachment" "exercise_fw_attachment" {
  firewall_id = hcloud_firewall.fw_exercise_15.id
  server_ids  = [hcloud_server.exercise_15.id]
  lifecycle {
    replace_triggered_by = [hcloud_server.exercise_15, hcloud_firewall.fw_exercise_15]
  }
}
