terraform {
  required_providers {
    dns = {
      source = "hashicorp/dns"
    }
  }
}

resource "dns_a_record_set" "exercise_dns_name_record" {
  zone      = "${var.zone}."
  name      = var.main_name
  addresses = [var.server_ip]
  ttl       = 10
}

resource "dns_cname_record" "exercise_dns_alias_records" {
  for_each = toset(var.alias)
  zone     = "${var.zone}."
  name     = each.key
  cname    = "${var.main_name}.${var.zone}."
  ttl      = 10
}
