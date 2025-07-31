terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
    acme = {
          source  = "vancluever/acme"
       }
  }
  required_version = ">= 0.13"
}

provider "acme" {
  server_url = "https://acme-staging-v02.api.letsencrypt.org/directory"
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
}

resource "acme_registration" "reg" {
  account_key_pem = tls_private_key.private_key.private_key_pem
  email_address   = "nobody@example.com"
}

resource "acme_certificate" "wildcard" {
  account_key_pem           = tls_private_key.private_key.private_key_pem
  common_name               = "*.g03.sdi.hdm-stuttgart.cloud"
  subject_alternative_names = ["g03.sdi.hdm-stuttgart.cloud"]

  dns_challenge {
    provider = "rfc2136"
    config = {
      RFC2136_NAMESERVER     = "ns1.sdi.hdm-stuttgart.cloud"
      RFC2136_TSIG_ALGORITHM = "hmac-sha512"
      RFC2136_TSIG_KEY       = "gxy.key."
      RFC2136_TSIG_SECRET    = var.dns_secret.content
    }
  }
}

resource "local_file" "private_key_pem" {
  content  = tls_private_key.private_key.private_key_pem
  filename = "${path.module}/../gen/private.pem"
}

resource "local_file" "certificate_pem" {
  content  = acme_certificate.wildcard.certificate_pem
  filename = "${path.module}/../gen/certificate.pem"
}

