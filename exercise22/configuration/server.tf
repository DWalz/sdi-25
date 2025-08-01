provider "hcloud" {
  token = var.hcloud_api_token
}

resource "hcloud_server" "exercise_22" {
  name        = "exercise-22"
  image       = "debian-12"
  server_type = "cpx11"
  location    = var.location
  user_data   = local_file.cloud_init.content
}

resource "hcloud_volume_attachment" "exercise_volume_attachment" {
  volume_id = hcloud_volume.volume_exercise_22.id
  server_id = hcloud_server.exercise_22.id
  automount = false
  lifecycle {
    replace_triggered_by = [hcloud_server.exercise_22, hcloud_volume.volume_exercise_22]
  }
}

resource "hcloud_firewall_attachment" "exercise_fw_attachment" {
  firewall_id = hcloud_firewall.fw_exercise_22.id
  server_ids  = [hcloud_server.exercise_22.id]
  lifecycle {
    replace_triggered_by = [hcloud_server.exercise_22, hcloud_firewall.fw_exercise_22]
  }
}

module "ssh_wrapper" {
  source            = "../modules/ssh_wrapper"
  server_hostname   = "${var.dns_server_name}.${var.dns_server_domain}"
  server_username   = var.server_username
  server_public_key = tls_private_key.server_ssh_key.public_key_openssh
  output_dir        = path.module
}
