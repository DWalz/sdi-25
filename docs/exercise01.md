# Exercise 1: Server Creation

## Documentation

A **Debian 12** server with the name `exercise-01` and a public IPv4 is
created using the Hetzner web console. The SSH key of the local computer
is attached to the server in order to avoid having to receive the
password of the root account via mail.

The created server has the IP `46.62.163.84`.

After the login using `ssh root@46.62.163.84` the following message appears:

```txt
The authenticity of host '46.62.163.84 (46.62.163.84)' can't be established.
ED25519 key fingerprint is SHA256:D2uCM+xEb8b/WQfiquGHiQWjh9xz3ZZFYBaoXtjDD9g.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])?
```

## Explanation

When connecting to any machine using SSH a **challenge-response protocol**
is being used to authenticate the user and the server against each
other. First the user (in this case the local computer) provides its
identity to the server, after that the server provides its identity to
the client (the local computer). If the identity is not previously known
it has to be manually accepted.

If idenities are listed inside the **`known_hosts`** file, they are known
and do not have to be specifically accepted. After manually accepting
the new server identity, it can now be found in the `known_hosts` file
of the local machine (for better readability `HashKnownHosts` has been
set to `no` in the `~/.ssh/config` file so that the hostnames are
visible as cleartext):

```txt
$ cat ~/.ssh/known_hosts
46.62.163.84 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5...
46.62.163.84 ssh-rsa AAAAB3NzaC1yc2EAAAAD...
46.62.163.84 ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTI...
```

Therefor any subsequent ssh connection to the server does not request
the acceptance of the fingerprint of the server as long as the hostname
of the server does not change.

## Additional Remarks

The **server does have to accept the identity of the client** in the same
way the client does - the identity must be authorized by the server on
connection attempt. Since the server was created with an already
**provided SSH key** (which is the public key of the local computer) it has
already been appended to the `authorized_keys` file of the `root`
account which in turn makes any client, which can prove this identity,
authorized to connect as root to the system:

```txt
root@exercise-01:~# cat ~/.ssh/authorized_keys
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDJzIgYTZw/zIxjxBqv2yJzB5buLEQgX6RKEowEOA4qL
```
