resource "local_file" "cloud_init" {
  filename = "./gen/cloud_init.yml"
  content = templatefile("./template/cloud_init.yml", {
    default_user     = var.server_username
    local_ssh_public = file("~/.ssh/id_ed25519.pub")
    ssh_private      = tls_private_key.server_ssh_key.private_key_openssh
    ssh_public       = tls_private_key.server_ssh_key.public_key_openssh
    volume_mount     = var.volume_mount
    volume_device    = hcloud_volume.volume_exercise_20.linux_device
  })
}
