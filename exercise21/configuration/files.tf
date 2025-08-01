resource "local_file" "cloud_init" {
  count    = var.server_count
  filename = "./server-${count.index}/gen/cloud_init.yml"
  content = templatefile("./template/cloud_init.yml", {
    default_user     = var.server_username
    local_ssh_public = file("~/.ssh/id_ed25519.pub")
    ssh_private      = tls_private_key.server_ssh_key[count.index].private_key_openssh
    ssh_public       = tls_private_key.server_ssh_key[count.index].public_key_openssh
    volume_mount     = var.volume_mount
    volume_device    = hcloud_volume.volume_exercise_21[count.index].linux_device
  })
}
