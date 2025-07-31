provider "dns" {
  update {
    server        = "ns1.hdm-stuttgart.cloud"
    key_name      = "g2.key."
    key_algorithm = "hmac-sha512"
    key_secret    = var.dns_secret_key
  }
}

resource "dns_a_record_set" "exercise_dns_base_record" {
  zone      = "${var.dns_server_domain}."
  addresses = [hcloud_server.exercise_20.ipv4_address]
  ttl       = 10
}

resource "dns_a_record_set" "exercise_dns_name_record" {
  zone      = "${var.dns_server_domain}."
  name      = var.dns_server_name
  addresses = [hcloud_server.exercise_20.ipv4_address]
  ttl       = 10
}

resource "dns_cname_record" "exercise_dns_alias_records" {
  for_each = toset(var.dns_server_aliases)
  zone     = "${var.dns_server_domain}."
  name     = each.key
  cname    = "${var.dns_server_name}.${var.dns_server_domain}."
  ttl      = 10
}

