# Custom DNS Module

This module creates a set of DNS records based on the inputs provided:

- An `A` record at `main_name.zone` pointing to the `server_ip`
- A `CNAME` record at `alias[i].zone` pointing to the `main_name.zone` specified earlier for each element in the `alias` list provided