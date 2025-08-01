provider "acme" {
  server_url = "https://acme-staging-v02.api.letsencrypt.org/directory"
  # server_url = "https://acme-v02.api.letsencrypt.org/directory"
}

resource "tls_private_key" "acme_account_private_key" {
  algorithm = "RSA"
}

resource "tls_private_key" "certificate_private_key" {
  algorithm = "RSA"
}

resource "acme_registration" "registration" {
  email_address   = "dw084@hdm-stuttgart.de"
  account_key_pem = tls_private_key.acme_account_private_key.private_key_pem
}

resource "acme_certificate" "wildcard_certificate" {
  account_key_pem           = acme_registration.registration.account_key_pem
  common_name               = "*.${var.dns_server_domain}"
  subject_alternative_names = [var.dns_server_domain]

  dns_challenge {
    provider = "rfc2136"
    config = {
      RFC2136_NAMESERVER     = "ns1.sdi.hdm-stuttgart.cloud"
      RFC2136_TSIG_ALGORITHM = "hmac-sha512"
      RFC2136_TSIG_KEY       = "g2.key."
      RFC2136_TSIG_SECRET    = var.dns_secret_key
    }
  }
}

resource "local_file" "tls_private_key" {
  filename        = "./gen/private.pem"
  content         = acme_certificate.wildcard_certificate.private_key_pem
  file_permission = "644"
}

resource "local_file" "tls_certificate_key" {
  filename        = "./gen/certificate.pem"
  content         = acme_certificate.wildcard_certificate.certificate_pem
  file_permission = "644"
}

