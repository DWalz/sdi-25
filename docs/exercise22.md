# Exercise 22: Creating a web certificate

> Click [here](https://github.com/DWalz/sdi-25/tree/main/exercise22) to view the solution in the repository.
>
> *Note:* The exercises 22 to 24 have been solved inside one configuration

The `acme` provider is used in Terraform to request certificates from different certificate servers implementing the ACME protocol.
To initialize the provider a server as well as a registration with that server is required:

```tf
provider "acme" {
  server_url = "https://acme-staging-v02.api.letsencrypt.org/directory"
  # server_url = "https://acme-v02.api.letsencrypt.org/directory"
}

resource "tls_private_key" "acme_account_private_key" {
  algorithm = "RSA"
}

resource "acme_registration" "registration" {
  email_address   = "dw084@hdm-stuttgart.de"
  account_key_pem = tls_private_key.acme_account_private_key.private_key_pem
}
```

The `acme_certificate` resource can then be used to request a certificate from that server.
To do so the name of the domain that the certificate is registered to (in this case `*.g2.sdi.hdm-stuttgart.cloud`) needs to be provided as well as any alternative names (in this case the zone domain `g2.hdm-stuttgart.cloud`).

The `dns_challenge` argument can be used to provide a DNS challenge in which the *Let's encrypt* server ensures that the necessary DNS entries are present in the DNS server before validating the certificate:

```tf
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
```

After the certificate has been created the values from it are used to save them to the `gen` folder in order to use them later (e.g. when applying them to a web server):

```tf
resource "local_file" "tls_private_key" {
  filename        = "./gen/private.pem"
  content         = acme_certificate.wildcard_certificate.private_key_pem
}

resource "local_file" "tls_certificate_key" {
  filename        = "./gen/certificate.pem"
  content         = acme_certificate.wildcard_certificate.certificate_pem
}
```
