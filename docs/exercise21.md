# Exercise 21: Creating a fixed number of servers

> Click [here](https://github.com/DWalz/sdi-25/tree/main/exercise21) to view the solution in the repository.
>
> *Note:* This exercise is not used as base for the following exercises since it modifies and complicates some main aspects of the configuration.

To be able to create a fixed number of servers, a lot of Terraform loops have to be used.
Every resource, that belongs to one server will have to be looped and all the references between the resources have to be adjusted.

## Export the DNS module

To prepare the process, the DNS registration process has been extracted into its own module: `custom_dns`.
It takes in the arguments given before (`zone`, `base_name`, `alias` and `server_ip`) and builds the DNS records everytime it is called.
This allows us to call the module in a loop for every server, drastically reducing the need for more loops.
It is important to note that the module doesn't need the provider specification explicitly.
As long as the provider is initialized in the root module it will be shared amongst called modules.
It is even possible to specify separate provider initalizations and pass them individually to called modules.

The created DNS module looks like the following (without variable declarations for brevity):

```tf
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
```

## Create Multiple Servers

With that we can begin to create multiple servers.
This is done using the Terraform `count` attribute which can be used to specify the number of that resource that should be created.
If it is specified the `count.index` variable becomes implicitly available, storing the index of the current resource instance.
This number can then be used by other referencing resources to select the right resource instance from the set:

```tf
resource "tls_private_key" "server_ssh_key" {
  count     = var.server_count
  algorithm = "ED25519"
}

resource "local_file" "cloud_init" {
  count    = var.server_count
  filename = "./server-${count.index}/gen/cloud_init.yml"
  content = templatefile("./template/cloud_init.yml", {
    default_user     = var.server_username
    local_ssh_public = file("~/.ssh/id_ed25519.pub")
    ssh_private      = tls_private_key.server_ssh_key[count.index].private_key_openssh
    ssh_public       = tls_private_key.server_ssh_key[count.index].public_key_openssh
    volume_mount     = var.volume_mount
    volume_device    = hcloud_volume.volume_exercise_20[count.index].linux_device
  })
}
```

Another example is the creation of the main server and the calling of the modules:

```tf
resource "hcloud_server" "exercise_20" {
  count       = var.server_count
  name        = "exercise-20-${count.index}"
  image       = "debian-12"
  server_type = "cpx11"
  location    = var.location
  user_data   = local_file.cloud_init[count.index].content
}

resource "hcloud_firewall_attachment" "exercise_fw_attachment" {
  count       = var.server_count
  firewall_id = hcloud_firewall.fw_exercise_20.id
  server_ids  = [hcloud_server.exercise_20[count.index].id]
  lifecycle {
    replace_triggered_by = [hcloud_server.exercise_20[count.index], hcloud_firewall.fw_exercise_20]
  }
}

module "ssh_wrapper" {
  count             = var.server_count
  source            = "../modules/ssh_wrapper"
  server_hostname   = "${var.dns_server_name}-${count.index}.${var.dns_server_domain}"
  server_username   = var.server_username
  server_public_key = tls_private_key.server_ssh_key[count.index].public_key_openssh
  output_dir        = "${path.module}/server-${count.index}"
}

module "custom_dns" {
  count     = var.server_count
  source    = "../modules/custom_dns"
  zone      = "g2.sdi.hdm-stuttgart.cloud"
  main_name = "${var.dns_server_name}-${count.index}"
  server_ip = hcloud_server.exercise_20[count.index].ipv4_address
  alias = [
    for alias in var.dns_server_aliases :
    "${alias}-${count.index}"
  ]
}
```

The `ssh_wrapper` module will deposit it's files based on the specified output file: `server-0/bin`, ... for the first server and `server-1/bin`, ... for the second one and so on.

As is visible in the `firewall_attachment` resource, the firewall does not need to be created multiple times.
It can simply be created once and be applied to multiple servers at the same time.

### Problems with the Approach

Note that the resources are not inherently connected: A mismatch in arity of the resources would lead to reference issues.
Since the variables are predefined the `terraform plan`/`terraform apply` commands would be able to derive the wrong references, but there is still a number of points of failure.
One has to be extremely careful in which resources need to be looped and which doesnt - forgetting one can "fail" silently and only create issues later or don't even be noticed at all.
If it was forgotten to duplicate the SSH keypair resource and the references, every server would have the same SSH private key and fingerprint - Terraform wouldn't notice this.

To better encapsulate this behavior it would be sensible to extract the actual resources into modules like the DNS module.
The module could then output values like the created server, volume and so on to allow access from the root module but this is beyond the scope of this exercise.

## The Working DNS Loop

Due to the loop call of the DNS module we can observe multiple DNS entries for every server:
One `A` record for each server pointing to it's IP and one `CNAME` record for every alias pointing to the main server.
Because there are multiple server now the base server has been removed as a main `A` record since there isn't only one single server we could point `g2.sdi.hdm-stuttgart.cloud` to.

Accessing the DNS records reveals that there is one record set for each server created:

```txt
$ dig +noall +answer @ns1.hdm-stuttgart.cloud -y $HMAC -t AXFR g2.sdi.hdm-stuttgart.cloud
g2.sdi.hdm-stuttgart.cloud. 600 IN      SOA     ns1.hdm-stuttgart.cloud. goik\@hdm-stuttgart.de. 40 604800 86400 2419200 604800
g2.sdi.hdm-stuttgart.cloud. 600 IN      NS      ns1.hdm-stuttgart.cloud.
mail-0.g2.sdi.hdm-stuttgart.cloud. 10 IN CNAME  work-0.g2.sdi.hdm-stuttgart.cloud.
mail-1.g2.sdi.hdm-stuttgart.cloud. 10 IN CNAME  work-1.g2.sdi.hdm-stuttgart.cloud.
work-0.g2.sdi.hdm-stuttgart.cloud. 10 IN A      157.180.35.105
work-1.g2.sdi.hdm-stuttgart.cloud. 10 IN A      37.27.219.19
www-0.g2.sdi.hdm-stuttgart.cloud. 10 IN CNAME   work-0.g2.sdi.hdm-stuttgart.cloud.
www-1.g2.sdi.hdm-stuttgart.cloud. 10 IN CNAME   work-1.g2.sdi.hdm-stuttgart.cloud.
g2.sdi.hdm-stuttgart.cloud. 600 IN      SOA     ns1.hdm-stuttgart.cloud. goik\@hdm-stuttgart.de. 40 604800 86400 2419200 604800
```
