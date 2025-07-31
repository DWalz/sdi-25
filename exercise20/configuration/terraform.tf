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