provider "hcloud" {
  token = var.hcloud_api_token
}

resource "hcloud_server" "exercise_19" {
  name        = "exercise-19"
  image       = "debian-12"
  server_type = "cpx11"
  location    = var.location
  user_data   = local_file.cloud_init.content
}

resource "hcloud_volume_attachment" "exercise_volume_attachment" {
  volume_id = hcloud_volume.volume_exercise_19.id
  server_id = hcloud_server.exercise_19.id
  automount = false
  lifecycle {
    replace_triggered_by = [hcloud_server.exercise_19, hcloud_volume.volume_exercise_19]
  }
}

resource "hcloud_firewall_attachment" "exercise_fw_attachment" {
  firewall_id = hcloud_firewall.fw_exercise_19.id
  server_ids  = [hcloud_server.exercise_19.id]
  lifecycle {
    replace_triggered_by = [hcloud_server.exercise_19, hcloud_firewall.fw_exercise_19]
  }
}

module "ssh_wrapper" {
  source            = "../modules/ssh_wrapper"
  server_hostname   = hcloud_server.exercise_19.ipv4_address
  server_username   = var.server_username
  server_public_key = tls_private_key.server_ssh_key.public_key_openssh
  output_dir        = path.module
}
