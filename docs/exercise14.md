# Exercise 14: Solving the `~/.ssh/known_hosts` quirk

As observed in [Exercise 2](./exercise02.md) the `ssh` program warns the
user every time the SSH fingerprint of a known host changes because such
a change can be the indication of a man-in-the-middle attack. To prevent
this error from occurring and to avoid the pollution of the
`~/.ssh/known_hosts` file on the local machine we can generate such a
`known_hosts` file ourself and tell the `ssh` program (and related
programs) to use this custom `known_hosts` file.

## Generation of the `known_hosts` file

The generation of the `known_hosts` file requires us to know the
fingerprint of the server. This is done by generating the SSH keypair on
the local machine and transferring it to the server using `cloud-init`.

The generation of a keypair can be done using the resource
`tls_private_key` and specifying the signature algorithm used:

```tf
resource "tls_private_key" "server_ssh_key" {
  algorithm = "ED25519"
}
```

This keypair will then be used when hydrating a `cloud-init` template
file with values. The public and private key are filled into the file
and the fully generated `cloud-init` file will then be run on the
server. With the usage of a template file it is also possible to stub
more than just the SSH keys. For simpler usage and transferability the
previously hardcoded `devops` username and SSH public key of the local
machine can also be injected dynamically allowing for more control of
the resulting server setup.

The following configuration is used in Terraform to create both the
custom `cloud_init` as well as the `known_hosts` file:

```tf
resource "local_file" "cloud_init" {
  filename = "./gen/cloud_init.yml"
  content = templatefile("./template/cloud_init.yml", {
    default_user     = var.server_username
    local_ssh_public = file("~/.ssh/id_ed25519.pub")
    ssh_private      = tls_private_key.server_ssh_key.private_key_openssh
    ssh_public       = tls_private_key.server_ssh_key.public_key_openssh
  })
}

resource "local_file" "known_hosts" {
  filename        = "./gen/known_hosts"
  content         = join(" ", [hcloud_server.exercise_14.ipv4_address, tls_private_key.server_ssh_key.public_key_openssh])
  file_permission = "644"
}
```

### YAML Files and Indentation

The `templatefile` function provided by Terraform simply replaces the
template strings of the form `${var_name}` with the provided values of
the variable `var_name`. This can especially lead to issues when
templating files in a format that is dependent on whitespace. Since the
private key file of a SSH keypair is usually multiple lines long this
leads to the follwing replacements inside the `cloud-init` file:

```yml
ssh_keys:
  ed25519_public: ${ssh_public}
  ed25519_private: ${ssh_private}
```

Will become:

```yml
ssh_keys:
  ed25519_private: -----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtz
...
-----END OPENSSH PRIVATE KEY-----
  ed25519_public: ssh-ed25519 AAAC3NzaC1lZDI1NTE5AAAAIHu7IFxgFGxalBAzKagNefEWGxgoBf9Et+gpEjnEmLKC
```

Which is not valid YAML. The `cloud-init` provision will fail and the
server will not behave as specified.

To resolve this issue there are two possible solutions: `yamlencode`.
`yamlencode` is a function provided by Terraform that can encode a valid
Terraform object structure into correctly formatted YAML:

```yml
${yamlencode({
  ssh_keys = {
    ed25519_public = ssh_public
    ed25519_private = ssh_private
  }
})}
```

Will expand to:

```yml
"ssh_keys":
  "ed25519_private": |
    -----BEGIN OPENSSH PRIVATE KEY-----
    b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtz
    ...
    -----END OPENSSH PRIVATE KEY-----
  "ed25519_public": |
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHu7IFxgFGxalBAzKagNefEWGxgoBf9Et+gpEjnEmLKC
```

Which is now correctly formatted.

## Generating Wrappers around `ssh` and `scp`

To now use the custom `known_hosts` file we can specify it to the `ssh`
program to use when connecting to the server: `ssh -o UserKnownHostsFile="./gen/known_hosts" devops@95.216.223.223`. To make connecting even more convenient we can now create a script
that executes this code since both username and IP address are also
known.

Similarly the `scp` program which is used to transfer files between
hosts using SSH can be wrapped in the same way.

For both files a template was created and the `templatefile` function
was used in a `local_file` resource for both files respectively:

```tf
resource "local_file" "ssh_bin" {
  filename = "./bin/ssh.sh"
  content = templatefile("./template/ssh.sh", {
    default_user = var.server_username
    ip           = hcloud_server.exercise_14.ipv4_address
  })
  file_permission = "755"
  depends_on      = [local_file.known_hosts]
}

resource "local_file" "scp_bin" {
  filename = "./bin/scp.sh"
  content = templatefile("./template/scp.sh", {
    default_user = var.server_username
    ip           = hcloud_server.exercise_14.ipv4_address
  })
  file_permission = "755"
  depends_on      = [local_file.known_hosts]
}
```

Different to the other `local_file` resources (like `known_hosts`) these
need some additional arguments: The file permission `755` needs to be
set which expands to `rwxr-xr-x`, giving the owner of the file read,
write and execute rights while everyone else gets read and execute
rights. This is important so that the generated script can be executed.
Additionally the `depends_on` argument is set to mark this file
dependent on the `known_hosts` file. It will only be generated after the
`known_hosts` file has been generated and respectively will be destroyed
before the `known_hosts` file will be destroyed to ensure the
depenedency chain.

The two files can now be used to transfer files between the local
machine and the server and connect in a very convenient way, all without
having to mess with any fingerprints again:

```txt
$ ./bin/scp.sh ./main.tf devops@95.216.223.223:~/test.tf
main.tf                             100% 2625    65.5KB/s   00:00
$ ./bin/ssh.sh
Linux exercise-14 6.1.0-37-amd64 #1 SMP PREEMPT_DYNAMIC Debian 6.1.140-1 (2025-05-22) x86_64
...
devops@exercise-14:~$ ls
test.tf
devops@exercise-14:~$
```
