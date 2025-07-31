resource "tls_private_key" "server_ssh_key" {
  count     = var.server_count
  algorithm = "ED25519"
}
