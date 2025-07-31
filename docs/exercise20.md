# Exercise 20: Creating a host with corresponding DNS entries

Since the creation of the `known_hosts` file and the `ssh`/`scp` wrappers is done in the `ssh_wrapper` module, the switch from IP based access to domain based access is simply a matter of exchanging the `server_hostname` input variable of the module.
The module will then generate the right files in the right places with the correct `server_hostname` used:

```tf
module "ssh_wrapper" {
  source            = "../modules/ssh_wrapper"
  server_hostname   = "${var.dns_server_name}.${var.dns_server_domain}"
  server_username   = var.server_username
  server_public_key = tls_private_key.server_ssh_key.public_key_openssh
  output_dir        = path.module
}
```

The resulting `known_hosts` and `ssh.sh` files have the adapted changes:

```txt
$ cat gen/known_hosts
workhorse.g2.sdi.hdm-stuttgart.cloud ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID1YDz27SNLycwLWVC0HFiZAMQuY9Ja0i0WkHiOpm2rX

$ cat bin/ssh.sh
#!/usr/bin/env bash
GEN_DIR=$(dirname "$0")/../gen
ssh -o UserKnownHostsFile="$GEN_DIR/known_hosts" devops@workhorse.g2.sdi.hdm-stuttgart.cloud "$@"
```

Connecting still works without a problem:

```txt
$ ./bin/ssh.sh
Linux exercise-20 6.1.0-37-amd64 #1 SMP PREEMPT_DYNAMIC Debian 6.1.140-1 (2025-05-22) x86_64

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
devops@exercise-20:~$
```