# Define Hetzner cloud provider
terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
  }
  required_version = ">= 0.14"
}

provider "hcloud" {
  token = var.hcloud_token
}

resource "hcloud_ssh_key" "loginUser" {
  name       = "sshkey-sn062"
  public_key = file("~/.ssh/id_ed25519.pub")
}

resource "hcloud_network" "privateNet" {
  name     = "Private network"
  ip_range = "10.0.0.0/8"
}

resource "hcloud_network_subnet" "privateSubnet" {
  network_id   = hcloud_network.privateNet.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = var.privateSubnet.ipAndNetmask
}

resource "hcloud_network_route" "gateway" {
  network_id  = hcloud_network.privateNet.id
  destination = "0.0.0.0/0"
  gateway     = "10.0.1.20"
}

resource "hcloud_primary_ip" "gateway_ip" {
  name          = "gateway-ip"
  datacenter    = "fsn1-dc14"
  type          = "ipv4"
  assignee_type = "server"
  auto_delete   = true
}

resource "hcloud_server" "gateway" {
  name        = "gateway"
  server_type = "cx22"
  image       = "debian-12"
  ssh_keys    = [ hcloud_ssh_key.loginUser.name ]

  public_net {
    ipv4 = hcloud_primary_ip.gateway_ip.id

  }

  network {
    network_id = hcloud_network.privateNet.id
    ip         = "10.0.1.20"
  }
}

resource "hcloud_server" "intern" {
  name        = "intern"
  server_type = "cx22"
  image       = "debian-12"
  ssh_keys    = [ hcloud_ssh_key.loginUser.name ]

  public_net {
    ipv4_enabled = false
    ipv6_enabled = false
  }

  network {
    network_id = hcloud_network.privateNet.id
    ip         = "10.0.1.30"
  }
}

