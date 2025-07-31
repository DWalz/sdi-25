resource "local_file" "known_hosts" {
  filename = "${var.output_dir}/gen/known_hosts"
  content = join(" ", [
    var.server_hostname,
    var.server_public_key
  ])
  file_permission = "644"
}

resource "local_file" "ssh_bin" {
  filename = "${var.output_dir}/bin/ssh.sh"
  content = templatefile("${path.module}/template/ssh.sh", {
    default_user = var.server_username
    ip           = var.server_hostname
  })
  file_permission = "755"
  depends_on      = [local_file.known_hosts]
}

resource "local_file" "scp_bin" {
  filename = "${var.output_dir}/bin/scp.sh"
  content = templatefile("${path.module}/template/scp.sh", {
    default_user = var.server_username
    ip           = var.server_hostname
  })
  file_permission = "755"
  depends_on      = [local_file.known_hosts]
}
