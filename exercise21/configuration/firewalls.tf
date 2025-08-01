resource "hcloud_firewall" "fw_exercise_21" {
  name = "exercise-21-fw"
  rule {
    description = "SSH inbound"
    direction   = "in"
    protocol    = "tcp"
    port        = 22
    source_ips  = ["0.0.0.0/0", "::/0"]
  }
  rule {
    description = "HTTP inbound"
    direction   = "in"
    protocol    = "tcp"
    port        = 80
    source_ips  = ["0.0.0.0/0", "::/0"]
  }
  rule {
    description = "HTTPS inbound"
    direction   = "in"
    protocol    = "tcp"
    port        = 443
    source_ips  = ["0.0.0.0/0", "::/0"]
  }
}
