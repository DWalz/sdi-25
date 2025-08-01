terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
    dns = {
      source = "hashicorp/dns"
    }
    acme = {
      source = "vancluever/acme"
    }
  }
}
