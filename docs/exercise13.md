# Exercise 13: Working on Cloud-init

Now instead of using a shell script to install and initialize `nginx`,
[`cloud-init`](https://cloudinit.readthedocs.io/en/latest/index.html) is used. Similarly to how Terraform is providing the
capabilities to describe an architecture as code and let terraform
handle the setup process, `cloud-init` provides the capabilites to
describe the server state as code and setup the sever respectively. The
following `cloud-init` configuration is used to install and enable
`nginx` as well as provide a custom landing page:

```yml
#cloud-config
packages:
  - nginx
runcmd:
  - systemctl enable nginx
  - rm /var/www/html/*
  - >
    echo "I'm Nginx @ $(dig -4 TXT +short o-o.myaddr.l.google.com @ns1.google.com)
    created $(date -u)" >> /var/www/html/index.html
```

The file can be passed as `user_data` into the server the same way that
the `nginx` installation script has been before:

```tf
resource "hcloud_server" "exercise_13" {
  ...
  user_data   = file("cloud_init.yml")
}
```

## Securing SSH login

When observing the `journalctl` log we can observe connection attempts
over SSH to our machine. These are automated attacks from botnets and
are meant to find and take over vulnerable servers that are connected to
the internet. They try random username + password combinations in order
attempt logging in to random machines on the internet. Within minutes of
the start of the server multiple of those attempts have been observed:

```txt
# journalctl -f
...
Jul 28 15:23:34 exercise-13 sshd[1785]: Invalid user admin from 103.114.246.37 port 31632
Jul 28 15:23:34 exercise-13 sshd[1785]: pam_unix(sshd:auth): check pass; user unknown
Jul 28 15:23:34 exercise-13 sshd[1785]: pam_unix(sshd:auth): authentication failure; logname= uid=0 euid=0 tty=ssh ruser= rhost=103.114.246.37
Jul 28 15:23:36 exercise-13 sshd[1787]: error: kex_exchange_identification: Connection closed by remote host
Jul 28 15:23:36 exercise-13 sshd[1787]: Connection closed by 196.251.114.29 port 51824
Jul 28 15:23:37 exercise-13 sshd[1785]: Failed password for invalid user admin from 103.114.246.37 port 31632 ssh2
Jul 28 15:23:37 exercise-13 sshd[1785]: Connection closed by invalid user admin 103.114.246.37 port 31632 [preauth]
```

In order to mitigate these attacks disabling the password login via SSH
altogether will prevent these attackers from randomly guessing the
password. To disable the password login in `cloud-init` the option
`ssh_pwauth` can be set to `false`.

Additionally it is generally a bad idea to have a root user just lying
about. It is better to have an alternative user for administrative
purposes which can execute privileged commands using `sudo`. In
`cloud-init` this can be achieved by first disabling the root user with
the `disable_root` option and then create a new user in the `users`
section with a name and a `sudo` option that allows it to execute using
`sudo`. To be able to log in as the new user it needs to have an
authorized SSH key that is accepted as passwordless login and can be
specified using `ssh-authorized-keys`.

The following config disables the password login and root user and sets
up a new user named `devops` with root rights and `bash` as default
shell:

```yml
ssh_pwauth: false
disable_root: true
users:
  - name: devops
    sudo: [ALL=(ALL) NOPASSWD:ALL]
    lock_passwd: true
    ssh-authorized-keys:
      - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPZ4lA1SGICnXIgP1QUH8kLCzVFRQh3/hSlz+rBZtfUn
    shell: /bin/bash
```

Attempting to login as `root` via ssh now fails. It doesn’t fail with
the message `Permission denied` for some reason, it rather says
`Please login as the user "NONE" rather than the user "root".` which
could be due to changes in `cloud-init`:

```txt
$ ssh root@157.180.35.105
...
Please login as the user "NONE" rather than the user "root".
```

The login to the newly created `devops` user is successful and the
acquisition of `root` works too:

```txt
$ ssh devops@157.180.35.105
...
devops@exercise-13:~$ sudo su -
root@exercise-13:~#
```

Investigating the `/etc/ssh/sshd_config` file shows, that `root` login
has not been disabled fully with these options:

```txt
$ grep PermitRoot /etc/ssh/sshd_config
PermitRootLogin prohibit-password
```

To fully disable root login this values has to be set to `no` which can
be done using `sed`:

```yml
...
runcmd:
  - sed -i -e '/^PermitRootLogin/s/^.*$/PermitRootLogin no/' /etc/ssh/sshd_config
  ...
```

## Installing `fail2ban` & `plocate`

To install `fail2ban` and `plocate` both packages simply have to be
added to the package list in the `cloud-init` file. But to make them
both work an some additional work is required.

In order for `plocate` to efficiently find files it needs to build a
file index database. The `plocate` package comes with a `updatedb`
command in order to do that. The command can simply be invoked in the
`runcmd` section of the `cloud-init` file.

For `fail2ban` there is a workaround necessary. The `python3-systemd`
package has to be installed additionally to make the `systemd` backend
available to `fail2ban`. On top of that the `jail.local` file has to be
created with some parameters for the `sshd` configuration of `fail2ban`.
Usually all default configuration lies in `/etc/fail2ban/jail.conf`.
Additional configuration can just be added to the
`/etc/fail2ban/jail.local` file which will then be merged with the
existing configuration in `jail.conf`. The following section has to be
added:

```toml
[sshd]
backend = systemd
enabled = true
```

This is done using the `echo` and `tee` commands in combination. After
that the `fail2ban` service has to be restarted using `sytemctl`.

All of the above steps are taken in the `cloud-init` file which now
looks like the following:

```yml
#cloud-config
ssh_pwauth: false
disable_root: true
users:
  - name: devops
    sudo: [ALL=(ALL) NOPASSWD:ALL]
    lock_passwd: true
    ssh-authorized-keys:
      - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPZ4lA1SGICnXIgP1QUH8kLCzVFRQh3/hSlz+rBZtfUn
    shell: /bin/bash
package_reboot_if_required: true
package_update: true
package_upgrade: true
packages:
  - nginx
  - fail2ban
  - python3-systemd
  - plocate
runcmd:
  - sed -i -e '/^PermitRootLogin/s/^.*$/PermitRootLogin no/' /etc/ssh/sshd_config
  # Fail2ban workaround
  - echo "[sshd]\nbackend = systemd\nenabled = true" | tee /etc/fail2ban/jail.local
  - systemctl restart fail2ban
  # Update plocate database
  - updatedb
  # Nginx
  - systemctl enable nginx
  - rm /var/www/html/*
  - >
    echo "I'm Nginx @ $(dig -4 TXT +short o-o.myaddr.l.google.com @ns1.google.com)
    created $(date -u)" >> /var/www/html/index.html
```

With that the login, sudo commands, `fail2ban` and `plocate` work like
intended:

```txt
$ ssh devops@157.180.35.105
...
devops@exercise-13:~$ plocate ssh_host
/etc/ssh/ssh_host_dsa_key
/etc/ssh/ssh_host_dsa_key.pub
...
devops@exercise-13:~$ sudo apt update
...
All packages are up to date.
devops@exercise-13:~$ sudo systemctl status fail2ban
● fail2ban.service - Fail2Ban Service
      Loaded: loaded (/lib/systemd/system/fail2ban.service; enabled; preset: enabled)
      Active: active (running) since Mon 2025-07-28 16:36:22 UTC; 19min ago
...
```


## Firewall Attachment Issues

At some point during the project Hetzner had issues with attaching, and especially removing firewalls from servers using the `firewall_ids` attribute in the server's definitions.
There was a technical issue that made firewall detachment take way longer than expected, resulting in firewalls being still assigned to a server resource while the server itself was already destructed at that point.
The firewalls couldn't be deleted anymore since they were still attached to a resource when in fact the resource was not existsing anymore leaving them orphaned.

To stop this issue from occuring a firewall attachment has explicitly been specified to connect the firewall to the server.
The Terraform `lifecycle` argument can then be used to force Terraform to replace the whole attachment on change of one of the resources referenced, stopping the implicit changes and attachments that were the issue before:

```tf
resource "hcloud_firewall_attachment" "exercise_fw_attachment" {
  firewall_id = hcloud_firewall.fw_exercise_13.id
  server_ids  = [hcloud_server.exercise_13.id]
  lifecycle {
    replace_triggered_by = [ hcloud_server.exercise_13, hcloud_firewall.fw_exercise_13 ]
  }
}
```

In the following exercises this method has been used throughout to mitigate this problem and prevent lots of orphaned firewalls in the group.
