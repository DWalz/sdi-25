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
  filename = "./gen/known_hosts"
  content = join(" ", [
    hcloud_server.exercise_15.ipv4_address,
    tls_private_key.server_ssh_key.public_key_openssh
  ])
  file_permission = "644"
}

resource "local_file" "ssh_bin" {
  filename = "./bin/ssh.sh"
  content = templatefile("./template/ssh.sh", {
    default_user = var.server_username
    ip           = hcloud_server.exercise_15.ipv4_address
  })
  file_permission = "755"
  depends_on      = [local_file.known_hosts]
}

resource "local_file" "scp_bin" {
  filename = "./bin/scp.sh"
  content = templatefile("./template/scp.sh", {
    default_user = var.server_username
    ip           = hcloud_server.exercise_15.ipv4_address
  })
  file_permission = "755"
  depends_on      = [local_file.known_hosts]
}
