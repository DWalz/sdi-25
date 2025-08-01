# Exercise 19: Creating DNS records

> Click [here](https://github.com/DWalz/sdi-25/tree/main/exercise19) to view the solution in the repository.

Currently the DNS configuration has only been done manually before in [Exercise 18](./exercise18.md).
If the Terraform configuration is destroyed and then applied the IP may change making all the DNS entries invalid.
It is much better to automatically create and update the DNS entries using Terraform.
To do that it is ensured that there are no leftover DNS entries in the `ns1.hdm-stuttgart.cloud` nameserver:

```txt
$ dig +noall +answer @ns1.hdm-stuttgart.cloud -y $HMAC -t AXFR g2.sdi.hdm-stuttgart.cloud
g2.sdi.hdm-stuttgart.cloud. 600 IN      SOA     ns1.hdm-stuttgart.cloud. goik\@hdm-stuttgart.de. 20 604800 86400 2419200 604800
g2.sdi.hdm-stuttgart.cloud. 600 IN      NS      ns1.hdm-stuttgart.cloud.
g2.sdi.hdm-stuttgart.cloud. 600 IN      SOA     ns1.hdm-stuttgart.cloud. goik\@hdm-stuttgart.de. 20 604800 86400 2419200 604800
```

To create different DNS records automatically in Terraform the `dns` provider can be used.
It has to be configured with the address and secret key of the server to be able to create, update and delete DNS records.
To hold the secret key, a variable has been created that will be injected using a non-versioned `secrets.auto.tfvars` file:

```tf
variable "dns_secret_key" {
  description = "Secret Key for the DNS nameserver"
  type        = string
  sensitive   = true
}

provider "dns" {
  update {
    server        = "ns1.hdm-stuttgart.cloud"
    key_name      = "g2.key."
    key_algorithm = "hmac-sha512"
    key_secret    = var.dns_secret_key
  }
}
```

In this exercise two types of DNS records should be created: `A` and `CNAME`.
`A` records have been discussed in [Exercise 18](./exercise18.md) before.
`CNAME` records are alias records: They point from one domain name to another domain name.
The domain they are aliasing will then have to be looked up, following the chain until an IP address is found.
The following records are created using Terraform:

- A base `A` record with the domain name `g2.sdi.hdm-stuttgart.cloud` pointing to the server IP
- A main `A` record with the name of the server appended to the domain (e.g. `workhorse.g2.sdi.hdm-stuttgart.cloud`) also pointing to the server IP
- A set of `CNAME` aliases, all pointing to the main `A` record (e.g. `mail.g2.sdi.hdm-stuttgart.cloud` and  `www.g2.sdi.hdm-stuttgart.cloud`)

To keep these records as modular as possible all the domains are specified using variables.
The base domain, a main server name as well as a set of alias names (entries are automatically unique), which is validated to not contain the main server name:

```tf
variable "dns_server_domain" {
  description = "The base domain of the server"
  type        = string
  default     = "g2.sdi.hdm-stuttgart.cloud"
}

variable "dns_server_name" {
  description = "The name of the server"
  type        = string
}

variable "dns_server_aliases" {
  description = "Alias names of the server"
  type        = set(string)
  default     = []
  validation {
    condition     = !contains(var.dns_server_aliases, var.dns_server_name)
    error_message = "Alias may not shadow the main name"
  }
}
```

These variables are then used to create the above mentioned set of DNS records.
The `A` records are straightforward.
They just take in the domain and the IP address the record is supposed to be pointing to.
The `CNAME` records take in the domain they are aliasing instead of the IP but due to there being a variable amount of aliases the `for_each` argument is used to create a Terraform loop which executes the resource once for every alias specified.
The implicit attribute `each.key` is then used to get the individual name of each alias.

```tf
resource "dns_a_record_set" "exercise_dns_base_record" {
  zone      = "${var.dns_server_domain}."
  addresses = [hcloud_server.exercise_19.ipv4_address]
  ttl       = 10
}

resource "dns_a_record_set" "exercise_dns_name_record" {
  zone      = "${var.dns_server_domain}."
  name      = var.dns_server_name
  addresses = [hcloud_server.exercise_19.ipv4_address]
  ttl       = 10
}

resource "dns_cname_record" "exercise_dns_alias_records" {
  for_each = toset(var.dns_server_aliases)
  zone     = "${var.dns_server_domain}."
  name     = each.key
  cname    = "${var.dns_server_name}.${var.dns_server_domain}."
  ttl      = 10
}
```

After running terraform apply now the DNS entries can be confirmed using `dig`.
They will also be removed again when running `terraform destroy`:

```txt
$ dig +noall +answer @ns1.hdm-stuttgart.cloud -y $HMAC -t AXFR g2.sdi.hdm-stuttgart.cloud
g2.sdi.hdm-stuttgart.cloud. 600 IN      SOA     ns1.hdm-stuttgart.cloud. goik\@hdm-stuttgart.de. 16 604800 86400 2419200 604800
g2.sdi.hdm-stuttgart.cloud. 10  IN      A       37.27.219.19
g2.sdi.hdm-stuttgart.cloud. 600 IN      NS      ns1.hdm-stuttgart.cloud.
mail.g2.sdi.hdm-stuttgart.cloud. 10 IN  CNAME   workhorse.g2.sdi.hdm-stuttgart.cloud.
workhorse.g2.sdi.hdm-stuttgart.cloud. 10 IN A   37.27.219.19
www.g2.sdi.hdm-stuttgart.cloud. 10 IN   CNAME   workhorse.g2.sdi.hdm-stuttgart.cloud.
g2.sdi.hdm-stuttgart.cloud. 600 IN      SOA     ns1.hdm-stuttgart.cloud. goik\@hdm-stuttgart.de. 16 604800 86400 2419200 604800

$ terraform destroy
...

$ dig +noall +answer @ns1.hdm-stuttgart.cloud -y $HMAC -t AXFR g2.sdi.hdm-stuttgart.cloud
g2.sdi.hdm-stuttgart.cloud. 600 IN      SOA     ns1.hdm-stuttgart.cloud. goik\@hdm-stuttgart.de. 20 604800 86400 2419200 604800
g2.sdi.hdm-stuttgart.cloud. 600 IN      NS      ns1.hdm-stuttgart.cloud.
g2.sdi.hdm-stuttgart.cloud. 600 IN      SOA     ns1.hdm-stuttgart.cloud. goik\@hdm-stuttgart.de. 20 604800 86400 2419200 604800
```