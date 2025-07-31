resource "hcloud_server" "exercise_20" {
  count       = var.server_count
  name        = "exercise-20-${count.index}"
  image       = "debian-12"
  server_type = "cpx11"
  location    = var.location
  user_data   = local_file.cloud_init[count.index].content
}

resource "hcloud_volume_attachment" "exercise_volume_attachment" {
  count     = var.server_count
  volume_id = hcloud_volume.volume_exercise_20[count.index].id
  server_id = hcloud_server.exercise_20[count.index].id
  automount = false
  lifecycle {
    replace_triggered_by = [hcloud_server.exercise_20[count.index], hcloud_volume.volume_exercise_20[count.index]]
  }
}

resource "hcloud_firewall_attachment" "exercise_fw_attachment" {
  count       = var.server_count
  firewall_id = hcloud_firewall.fw_exercise_20.id
  server_ids  = [hcloud_server.exercise_20[count.index].id]
  lifecycle {
    replace_triggered_by = [hcloud_server.exercise_20[count.index], hcloud_firewall.fw_exercise_20]
  }
}

module "ssh_wrapper" {
  count             = var.server_count
  source            = "../modules/ssh_wrapper"
  server_hostname   = "${var.dns_server_name}-${count.index}.${var.dns_server_domain}"
  server_username   = var.server_username
  server_public_key = tls_private_key.server_ssh_key[count.index].public_key_openssh
  output_dir        = "${path.module}/server-${count.index}"
}

module "custom_dns" {
  count     = var.server_count
  source    = "../modules/custom_dns"
  zone      = "g2.sdi.hdm-stuttgart.cloud"
  main_name = "${var.dns_server_name}-${count.index}"
  server_ip = hcloud_server.exercise_20[count.index].ipv4_address
  alias = [
    for alias in var.dns_server_aliases :
    "${alias}-${count.index}"
  ]
}
