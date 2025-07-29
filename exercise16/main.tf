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

resource "hcloud_server" "exercise_16" {
  name        = "exercise-16"
  image       = "debian-12"
  server_type = "cpx11"
  location    = var.location
  user_data   = local_file.cloud_init.content
}

resource "hcloud_volume_attachment" "exercise_volume_attachment" {
  volume_id = hcloud_volume.volume_exercise_16.id
  server_id = hcloud_server.exercise_16.id
  automount = false
  lifecycle {
    replace_triggered_by = [hcloud_server.exercise_16, hcloud_volume.volume_exercise_16]
  }
}

resource "hcloud_firewall_attachment" "exercise_fw_attachment" {
  firewall_id = hcloud_firewall.fw_exercise_16.id
  server_ids  = [hcloud_server.exercise_16.id]
  lifecycle {
    replace_triggered_by = [hcloud_server.exercise_16, hcloud_firewall.fw_exercise_16]
  }
}
