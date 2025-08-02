
resource "hcloud_firewall" "gateway_firewall" {
  name = "gateway-fw"

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = ["0.0.0.0/0", "::/0"]
    description = "Allow SSH from anywhere"
  }

  rule {
    direction  = "in"
    protocol   = "icmp"
    source_ips = ["0.0.0.0/0", "::/0"]
    description = "Allow ping"
  }
}

resource "hcloud_firewall_attachment" "gateway_attach" {
  firewall_id = hcloud_firewall.gateway_firewall.id
  server_ids  = [hcloud_server.gateway.id]
}
