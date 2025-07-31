terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.51.0"
    }
    dns = {
      source = "hashicorp/dns"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_api_token
}

provider "dns" {
  update {
    server        = "ns1.hdm-stuttgart.cloud"
    key_name      = "g2.key."
    key_algorithm = "hmac-sha512"
    key_secret    = var.dns_secret_key
  }
}
