= Software Defined Infrastructure

== Exercise 1: Server Creation <exercise-01>

=== Documentation

A Debian 12 server with the name `exercise-01` and a public IPv4 is created using the Hetzner web console.
The SSH key of the local computer is attached to the server in order to avoid having to receive the password of the root account via mail.

The created server has the IP `46.62.163.84`.

After the login using ```bash ssh root@46.62.163.84``` the following message appears:

```
The authenticity of host '46.62.163.84 (46.62.163.84)' can't be established.
ED25519 key fingerprint is SHA256:D2uCM+xEb8b/WQfiquGHiQWjh9xz3ZZFYBaoXtjDD9g.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])?
```

=== Explanation

When connecting to any machine using SSH a challenge-response protocol is being used to authenticate the user and the server against each other.
First the user (in this case the local computer) provides its identity to the server, after that the server provides its identity to the client (the local computer).
If the identity is not previously known it has to be manually accepted.

If idenities are listed inside the `known_hosts` file, they are known and do not have to be specifically accepted.
After manually accepting the new server identity, it can now be found in the `known_hosts` file of the lcoal machine (for better readability `HashKnownHosts` has been set to `no` in the `~/.ssh/config` file so that the hostnames are visible as cleartext):

```
$ cat ~/.ssh/known_hosts
46.62.163.84 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5...
46.62.163.84 ssh-rsa AAAAB3NzaC1yc2EAAAAD...
46.62.163.84 ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTI...
```

Therefor any subsequent ssh connection to the server does not request the acceptance of the fingerprint of the server as long as the hostname of the server does not change.

=== Additional Remarks

The server does have to accept the identity of the client in the same way the client does - the identity must be authorized by the server on connection attempt.
Since the server was created with an already provided SSH key (which is the public key of the local computer) it has already been appended to the `authorized_keys` file of the `root` account which in turn makes any client which can prove this identity authorized to connect as root to the system:

```
root@exercise-01:~# cat ~/.ssh/authorized_keys
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDJzIgYTZw/zIxjxBqv2yJzB5buLEQgX6RKEowEOA4qL
```

== Exercise 2: Server re-creation

=== Documentation

The server `exercise-02` with the same configuration as the one from #link(<exercise-01>)[Exercise 1] has been created.
Additionally the same IP addresses have been reused.

When connecting to the server now using ```bash ssh root@46.62.163.84``` the following error message appears:

```
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
IT IS POSSIBLE THAT SOMEONE IS DOING SOMETHING NASTY!
Someone could be eavesdropping on you right now (man-in-the-middle attack)!
It is also possible that a host key has just been changed.
The fingerprint for the ED25519 key sent by the remote host is
SHA256:aPHbFitv2gzPSk6lqJVrNPKVjthnaJL270H0zY1QNt0.
Please contact your system administrator.
Add correct host key in /home/dwalz/.ssh/known_hosts to get rid of this message.
Offending ECDSA key in /home/dwalz/.ssh/known_hosts:3
  remove with:
  ssh-keygen -f '/home/dwalz/.ssh/known_hosts' -R '46.62.163.84'
Host key for 46.62.163.84 has changed and you have requested strict checking.
Host key verification failed.
```

=== Explanation

This message is happens because the identity associated with the host `46.62.163.84` inside the `known_hosts` file differs from the key the server has provided now.
As soon as a known host provides a different identity this error message occurs and warns the user from possible security implications.
There is usually two reasons for such a scenario, both of which are listed in the error message:

The first possibility is that the host changed its identity for some reason by exchanging the shh key pair for a different one (for example if the private key of the server gets compromised).

The second possibility and the possibility experienced now is that a new server is using the same hostname.
In this specific case it is not security relevant since there is no relevant data on the created servers but the new server that is serving on the same host could also be a man in the middle server that is pretending to be the old service.
In such a case it could read all the data that would usually be transmitted including sensitive information that `ssh` is built to handle.
This is why it is very important to mistrust servers should such messages appear when connecting and double check if possible.

=== Solution

Since it is known that the change in this case stems from a new server being created replacing the old one at the same IP this warning can be disregarded as a normal occurence.
To fix the error message the offending entries in the `known_hosts` file have to be removed either manually or using the command provided by the error message:

```bash
ssh-keygen -f '~/.ssh/known_hosts' -R '46.62.163.84'
```

After that the host `46.62.163.84` is no longer associated with the identity of the old server and the connection to the new server can be established normally.

== Exercise 3: Improve your server's security!

A firewall with the name `fw-exercise-03` has been created with a single inbound rule for *ICMP* traffic.
The server `exercise-03` has been created using the new firewall and the same procedure as the previous exercises.
The server IP for `exercise-03` is `46.62.163.84`.

Pinging the server with ```bash ping 46.62.163.84``` results in successful ping answers but trying to connect using ```bash ssh root@46.62.163.84``` results in a timeout.

=== Firewalls and SSH

Firewalls work on a whitelist principle.
This means that as soon as a firewall is applied all traffic is forbidden except the traffic allowed by the firewall's rules.
Currently the firewall limits incoming traffic to use the *ICMP* protocol which is used to exchange operation information (for example the "alive-ness" when using `ping`) which results in traffic using the *TCP* protocol (and any other protocol) to be blocked.
SSH is using *TCP* on port `22` and is therefor blocked.

After adding an inbound *TCP* rule on port `22` both `ping` and `ssh` access are successful.

=== Nginx Installation

The server was updated and rebooted.
After the reboot `nginx` has been installed and the status of the `nginx` service has been confirmed:

```
# systemctl status nginx
● nginx.service - A high performance web server and a reverse proxy server
     Loaded: loaded (/lib/systemd/system/nginx.service; enabled; preset: enabled)
     Active: active (running) since Mon 2025-07-21 12:03:09 UTC; 10s ago
     ...
```

*Nginx* is a server application that is used to host websites and other web services.
The websites served by *nginx* are by default accessed using the HTTP protocol which is served via TCP on port `80`.
The command `wget` can be used to access the content of the default generated website served by `nginx`:

```
root@exercise-03:~# wget -O - http://46.62.163.84
Connecting to 46.62.163.84:80... connected.
HTTP request sent, awaiting response... 200 OK
Length: 615 [text/html]
Saving to: ‘STDOUT’

<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
```

=== Nginx & Firewall

When trying to get the file from the local computer the connection fails with a timeout similarly to the SSH case before.
The firewall once again blocks all incoming traffic that is not whitelisted by a firewall rule.
Since HTTP used TCP over port 80 the current firewall setup blocks the incoming HTTP traffic.

Since the firewall sits between the server and the internet, requests can be made from the server to itself.
The firewall would block such traffic were it to receive it but since it is just routed using the loopback interface of the server it will not reach any other network interface other than the server itself.

After an inbound rule for TCP port `80` is added the website can be accessed from outside too.

```
$ wget -O - http://46.62.163.84
Connecting to 46.62.163.84:80... connected.
HTTP request sent, awaiting response... 200 OK
Length: 615 [text/html]
Saving to: ‘STDOUT’

<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
```

== Exercise 4: `ssh-agent` installation

`ssh-agent` has been installed on the local system.
Now every first time a login session needs to use the private key to establish connections the agent asks for the passphrase of the active key.
Every following request is then answered by the ssh-agent alleviating the user of the need to enter the passphrase every time it has to be used by the SSH client.

This can also be combined with the #link("https://github.com/funtoo/keychain")[`keychain`] package to further reduce the need to enter the passphrase to once every system reboot.

== Exercise 5: MI Gitlab access by ssh

Under _Preferences/SSH Keys_ the public SSH key of the local machine has been added.
This has for example been used to push the first three exercises of this documentation to the MI Gitlab:

```
# git remote add origin git@gitlab.mi.hdm-stuttgart.de:sdi-dw084/sdi.git
# git push --set-upstream origin --all
Enumerating objects: 6, done.
Counting objects: 100% (6/6), done.
Delta compression using up to 24 threads
Compressing objects: 100% (5/5), done.
Writing objects: 100% (6/6), 3.96 KiB | 3.96 MiB/s, done.
Total 6 (delta 0), reused 0 (delta 0), pack-reused 0 (from 0)
```

== Exercise 11: Incrementally creating a base system

=== Minimal Configuration and Basics

The minimal configuration contained in the mentioned figure has been copied into the file `main.tf`.
Running ```bash terraform init``` initializes the provider module from the Hetzner Cloud specified in the top of the file.
This allows us to use all the definitions of Hetzner in Terraform to manage the server infrastructure of the project via Terraform.

The `hcloud_server` resource which is specifying a server instance in ouc configuration has been renamed to `exercise_11` for better identification.
Running ```bash terraform plan``` right now, Terraform will us inform of changes it will make to the current configuration present in the cloud.
The proposed changes follow the specifications made in the configuration:

```
$ terraform plan
...
Terraform will perform the following actions:

  # hcloud_server.exercise_11 will be created
  + resource "hcloud_server" "exercise_11" {
      + image                      = "debian-12"
      + name                       = "exercise-11"
      + server_type                = "cx22"
      + ipv4_address               = (known after apply)
     ...
    }

Plan: 1 to add, 0 to change, 0 to destroy.
```

=== Adding the SSH Firewall

To add an SSH firewall to the server a `hcloud_firewall` resource has to be created which represents a firewall object in the Hetzner Cloud.
The firewall has to have a single inbound rule for TCP traffic on port 22:

```tf
resource "hcloud_firewall" "fw_ssh" {
  name = "exercise-11-fw-ssh"
  rule {
    description = "SSH inbound"
    direction   = "in"
    protocol    = "tcp"
    port        = 22
    source_ips  = ["0.0.0.0/0", "::/0"]
  }
}
```

Important to notice here is that the rule also has to specify the `source_ips` which is the list of allowed IPs that the SSH traffic may be sent from.
Setting them to `0.0.0.0/0` for IPv4 and `::/0` for IPv6 addresses respectively allows any sender on the internet to send SSH packets to the server.

To apply the firewall to the server, it has to be connected to it in the terraform configuration.
The `hcloud_server` resource has the field `firewall_ids` which can be used to provide a list of IDs of firewalls to apply to that server.
The firewall resource that has been created is passed into this list to apply the firewall to the server.
Terraform allows us to reference the field of other resources by reference to fill them out once they become available.
This means there is no need for manually transferring the ID of a created firewall resouce to the server resource definition:

```tf
resource "hcloud_server" "exercise_11" {
  name         = "exercise-11"
  image        = "debian-12"
  server_type  = "cx22"
  firewall_ids = [hcloud_firewall.fw_ssh.id]
}
```

#figure(image("images/server_ssh_firewall.png"), caption: [Server with applied SSH firewall in the Hetzner Web Console.]) <server_with_ssh_firewall>

=== Applying the Configuration to the Cloud

Running ```bash terraform plan``` will once again show changes that will be made to the infrastructure.
In this case there will be two resources created: The firewall and the server resource.
With ```bash terraform apply``` the planned configuration will then be acted upon and will be created in the Hetzner Cloud.

In the Cloud Console the created server and firewall can now be observed.
The server has an IP of `37.27.219.19` and the applied firewall can be seen.
Pinging the server now would fail, since there is no ICMP firewall is configured for the server which would allow any ping traffic to it.
The only way to reach it would be via SSH using ```bash ssh root@37.27.219.19```.

Sadly, the automatic E-Mail was never sent to the E-Mail account provided to Hetzner and therefor the root password was unknown.
It can be reset using the `Rescue` tab in the Cloud Console to still connect to the server.
A way better option however is to provide a SSH key to the server upon creation like in #link(<exercise-01>)[Exercise 1].

=== Version Control and Secrets

Currently the private API token for the Hetzner API is readable in plain text inside the `main.tf` file making it unable to be used in version control like Git.
To circumvent the issue the token has to be specified as a variable which can then be used in the initialization of the `hcloud` provider.
This makes it possible to load the variable from another file and then apply it without it ever having to be present in the configuration file:

```tf
variable "hcloud_api_token" {
  description = "API token for the Hetzner Cloud"
  type        = string
  sensitive   = true
}
```

This variable can now be used instead of the hardcoded value inside the `hcloud` provider:

```tf
provider "hcloud" {
  token = var.hcloud_api_token
}
```

Now the variable only has to be specified.
Right now when using ```bash terraform apply``` Terraform will ask for the value of the variable:

```
$ terraform apply
var.hcloud_api_token
  API token for the Hetzner Cloud

  Enter a value:
```

We can either input the API token every time using the CLI or alternatively use a `*.tfvars` file to specify the variables.
In this case the file `secrets.tfvars` is used to provide a value to the `hcloud_api_token`:

```tf
hcloud_api_token = "..."
```

The variable file has to be loaded during the application using ```bash terraform apply -var-file=secrets.tfvars```.
To prevent the necessity of having to provide the file every time a Terraform command has to be used, the variable file can also be named `*.auto.tfvars` to load them automatically.
This way the usage of Terraform remains simple.

Now the `*.tfvars` files can be excluded from versioning to keep any sensitive information outside of version control.

=== SSH Passwordless Login

To be able to log in to the server without using a password we have to add the public key of the local machine to the server's `authorized_keys` file.
To register a SSH key in the Hetzner Cloud the `hcloud_ssh_key` resource is used.
In it the `public_key` can be provided from either a file or as a string:

```tf
resource "hcloud_ssh_key" "dw084_ssh_key" {
  name       = "dw084-ssh-key"
  public_key = file("~/.ssh/id_ed25519.pub")
}
```

This SSH key can then be added to the server using the `ssh_keys` field in which a list of `hcloud_ssh_key` IDs can be specified to be added to the respective server:

```tf
resource "hcloud_server" "exercise_11" {
  ...
  ssh_keys     = [hcloud_ssh_key.dw084_ssh_key.id]
}
```

After using ```bash terraform apply``` to create the infrastructure the login into the server works without having to enter any passwords:

```
$ ssh root@37.27.219.19
...
root@exercise-11:~#
```

=== Creating Outputs for Server Properties

Some properties of created resources like the server's IP can't be known before applying the configuration.
After the creation these values will become known to Terraform and can be displayed using a file named `outputs.tf`.

In this file there may be arbitrary `output` sections created.
They all have a `value` which may reference any static or dynamic values to display after successful usage of the ```bash terraform apply``` command.
To display the IP and datacenter of the created server the `ipv4_address` and `datacenter` attribute of the `hcloud_server` resource are used respectively:

```tf
output "server_ip" {
  description = "IP of the server created in exercise 11"
  value       = hcloud_server.exercise_11.ipv4_address
}

output "server_datacenter" {
  description = "Datacenter of the server created in exercise 11"
  value       = hcloud_server.exercise_11.datacenter
}
```

Now these two values are being displayed when running ```bash terraform apply```:

```
$ terraform apply
...
server_datacenter = "hel1-dc2"
server_ip = "37.27.219.19"
```

== Exercise 12: Automatic Nginx installation

The following script can be used to install, start and enable (make it survive a re-boot) the `nginx` package on the server the following script has been created.
It will update the system first ```bash apt-get update``` and ```bash apt-get -y upgrade``` and after that install Nginx and enable it using the `systemctl`:

```bash
#!/bin/sh
# Update installation
apt-get update
apt-get -y upgrade

# Install nginx
apt-get -y install nginx

# Start and enable (survive after re-boot) nginx
systemctl start nginx
systemctl enable nginx
```

To make the script run on server start the `user_data` argument is used to pass the file to terraform.
It will be applied to the server once it starts.

To be able to reach the webserver and test the success of installing `nginx` the server needs a firewall that allows incoming HTTP traffic.
This is done by adding a rule for the TCP protocol on port 80:

```tf
resource "hcloud_firewall" "fw_exercise_12" {
  name = "exercise-12-fw"
  ...
  rule {
    description = "HTTP inbound"
    direction   = "in"
    protocol    = "tcp"
    port        = 80
    source_ips  = ["0.0.0.0/0", "::/0"]
  }
}
```

When accessing the website in the browser under `http://95.216.223.223` the `nginx` default landing page can be observed.
Even after a server restart there is no additional commands that need to be executed on the server to make `nginx` running again thus showing the landing page immediately.

#figure(image("images/nginx_landing_page.png"), caption: [`nginx` landing page.]) <nginx_landing>

== Exercise 13: Working on Cloud-init

Now instead of using a shell script to install and initialize `nginx`, `cloud-init` is used.
Similarly to how Terraform is providing the capabilities to describe an architecture as code and let terraform handle the setup process, `cloud-init` provides the capabilites to describe the server state as code and setup the sever respectively.
The following `cloud-init` configuration is used to install and enable `nginx` as well as provide a custom landing page:

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

The file can be passed as `user_data` into the server the same way that the `nginx` installation script has been before:

```tf
resource "hcloud_server" "exercise_13" {
  ...
  user_data   = file("cloud_init.yml")
}
```

=== Securing SSH login

When observing the `journalctl` log we can observe connection attempts over SSH to our machine.
These are automated attacks from botnets and are meant to find and take over vulnerable servers that are connected to the internet.
They try random username + password combinations in order attempt logging in to random machines on the internet.
Within minutes of the start of the server multiple of those attempts have been observed:

```
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

In order to mitigate these attacks disabling the password login via SSH altogether will prevent these attackers from randomly guessing the password.
To disable the password login in `cloud-init` the option `ssh_pwauth` can be set to `false`.

Additionally it is generally a bad idea to have a root user just lying about.
It is better to have an alternative user for administrative purposes which can execute privileged commands using `sudo`. 
In `cloud-init` this can be achieved by first disabling the root user with the `disable_root` option and then create a new user in the `users` section with a name and a `sudo` option that allows it to execute using `sudo`.
To be able to log in as the new user it needs to have an authorized SSH key that is accepted as passwordless login and can be specified using `ssh-authorized-keys`.

The following config disables the password login and root user and sets up a new user named `devops` with root rights and `bash` as default shell:

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

Attempting to login as `root` via ssh now fails.
It doesn't fail with the message `Permission denied` for some reason, it rather says `Please login as the user "NONE" rather than the user "root".` which could be due to changes in `cloud-init`:

```
$ ssh root@157.180.35.105
...
Please login as the user "NONE" rather than the user "root".
```

The login to the newly created `devops` user is successful and the acquisition of `root` works too:

```
$ ssh devops@157.180.35.105
...
devops@exercise-13:~$ sudo su -
root@exercise-13:~#
```

Investigating the `/etc/ssh/sshd_config` file shows, that `root` login has not been disabled fully with these options:

```
$ grep PermitRoot /etc/ssh/sshd_config
PermitRootLogin prohibit-password
```

To fully disable root login this values has to be set to `no` which can be done using `sed`:

```yml
...
runcmd:
  - sed -i -e '/^PermitRootLogin/s/^.*$/PermitRootLogin no/' /etc/ssh/sshd_config
  ...
```

=== Installing `fail2ban` & `plocate`

To install `fail2ban` and `plocate` both packages simply have to be added to the package list in the `cloud-init` file.
But to make them both work an some additional work is required.

In order for `plocate` to efficiently find files it needs to build a file index database.
The `plocate` package comes with a `updatedb` command in order to do that.
The command can simply be invoked in the `runcmd` section of the `cloud-init` file.

For `fail2ban` there is a workaround necessary.
The `python3-systemd` package has to be installed additionally to make the `systemd` backend available to `fail2ban`.
On top of that the `jail.local` file has to be created with some parameters for the `sshd` configuration of `fail2ban`.
Usually all default configuration lies in `/etc/fail2ban/jail.conf`.
Additional configuration can just be added to the `/etc/fail2ban/jail.local` file which will then be merged with the existing configuration in `jail.conf`.
The following section has to be added:

```toml
[sshd]
backend = systemd
enabled = true
```

This is done using the `echo` and `tee` commands in combination.
After that the `fail2ban` service has to be restarted using `sytemctl`.

All of the above steps are taken in the `cloud-init` file which now looks like the following:

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

With that the login, sudo commands, `fail2ban` and `plocate` work like intended:

```
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