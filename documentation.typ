#set page(numbering: "1")

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

== Exercise 2: Server re-creation <exercise-02>

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

== Exercise 3: Improve your server's security! <exercise-03>

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

== Exercise 6: ssh host hopping <exercise-06>

Two Debian 12 servers named `host-a` and `host-b` were created via the Hetzner Cloud console.
Both servers were configured with the same public SSH key to allow access from the local workstation.

`host-a` has both the public IPv4 `65.21.182.46` and is part of a private network with the IP `10.0.0.2`.
`host-b` has only a private IPv4 and is also part of the same private network with the IP `10.0.0.3`.

On the local workstation, the private SSH key is loaded into the SSH agent using:

```
ssh-add ~/.ssh/id_ed25519
```

Then with the agent forwarding active a SSH connection is established:

```
ssh -A root@65.21.182.46
```

From `host-a` a second SSH connection is started to `host-b` using its private IP:

```
ssh root@10.0.0.3
```

After logging out of both hosts, the connection sequence is repeated in the same order, first `host-a` then `host-b`.
While logged inot `host-b`, an attempt is made to open a SSH connecetion into host-a. This results in a password prompt,
despite agent forwarding being enabled on the inital workstation connection.

Exit from `host-b` to then restart the connection from `host-a` to `host-b` this time using agent forwarding a second time:

```
ssh -A root@10.0.0.2
```

Now when logged into `host-b` and conneceting back to `host-a`, no password prompt appears and the login is successfull.

=== Explanation

SSH agent forwarding allows the credentials of a local workstation to be securly forwarded to remote machines.
This enables indirect authentication which means a user on host-a can prove his identity to `host-b` using the agent
running on the original workstation without storing keys on any server.

However agent forwarding is not transitive by default.
If `host-a` connects to `host-b` without forwaring its own agent (`-A`), then `host-b` has no access to the forwaded
credentials and cannot connect back to `host-a` without prompting for a password.

== Exercise 7: ssh port forwarding

The server `exercise-07` was created with the same configurations as the final one from #link(<exercise-03>)[Exercise 3].
The server has the same IP as `host-a` from #link(<exercise-06>)[Exercise 6].

A quick test shows that Nginx is accessible:

```
curl http://95.216.223.223
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
```

The firewall configuration was updated to allow only SSH (port `22`) and block HTTP (port `80`) from public access.
Attempting to access the HTTP service from the local machine again shows:

```
curl -O - http://65.21.182.46
curl: (28) Failed to connect to 65.21.182.46 port 80 after 75003 ms: Couldn't connect to server
```

To test HTTP access securly a local SSH tunnel is needed:

```
ssh -L 2000:localhost:80 root@65.21.182.46 -N
```

This command forwards local port 2000 on the workstation to port 80 on the remote server through SSH.
Visiting the following URL in a local brwoser:

```
http://localhost:2000
```
renders the default Nginx welcome page, confirming that the HTTP service is accessible only through the SSH tunnel.

=== Explanation

SSH local port forwarding is a powerful feature that allows tunneling of TCP connecetions through a secure channel.
By forwarding local port 2000 to port 80 on the remote host, it becomes possible to access the remote web server
without exposing it to the public internet.

This approch is useful for secure access to internal or restricted servies without altering firewall rules.


== Exercise 11: Incrementally creating a base system

=== Minimal Configuration and Basics

The minimal configuration contained in the mentioned figure has been copied into the file `main.tf`.
Running ```bash terraform init``` initializes the provider module from the Hetzner Cloud specified at the top of the file.
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

== Exercise 14: Solving the `~/.ssh/known_hosts` quirk

As observed in #link(<exercise-02>)[Exercise 2] the `ssh` program warns the user every time the SSH fingerprint of a known host changes because such a change can be the indication of a man-in-the-middle attack.
To prevent this error from occurring and to avoid the pollution of the `~/.ssh/known_hosts` file on the local machine we can generate such a `known_hosts` file ourself and tell the `ssh` program (and related programs) to use this custom `known_hosts` file.

=== Generation of the `known_hosts` file

The generation of the `known_hosts` file requires us to know the fingerprint of the server.
This is done by generating the SSH keypair on the local machine and transferring it to the server using `cloud-init`.

The generation of a keypair can be done using the resource `tls_private_key` and specifying the signature algorithm used:

```tf
resource "tls_private_key" "server_ssh_key" {
  algorithm = "ED25519"
}
```

This keypair will then be used when hydrating a `cloud-init` template file with values.
The public and private key are filled into the file and the fully generated `cloud-init` file will then be run on the server.
With the usage of a template file it is also possible to stub more than just the SSH keys.
For simpler usage and transferability the previously hardcoded `devops` username and SSH public key of the local machine can also be injected dynamically allowing for more control of the resulting server setup.

The following configuration is used in Terraform to create both the custom `cloud_init` as well as the `known_hosts` file:

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

==== YAML Files and Indentation

The `templatefile` function provided by Terraform simply replaces the template strings of the form `${var_name}` with the provided values of the variable `var_name`.
This can especially lead to issues when templating files in a format that is dependent on whitespace.
Since the private key file of a SSH keypair is usually multiple lines long this leads to the follwing replacements inside the `cloud-init` file:

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

Which is not valid YAML.
The `cloud-init` provision will fail and the server will not behave as specified.

To resolve this issue there are two possible solutions: `yamlencode`.
`yamlencode` is a function provided by Terraform that can encode a valid Terraform object structure into correctly formatted YAML:

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

=== Generating Wrappers around `ssh` and `scp`

To now use the custom `known_hosts` file we can specify it to the `ssh` program to use when connecting to the server: ```bash ssh -o UserKnownHostsFile="./gen/known_hosts" devops@95.216.223.223```.
To make connecting even more convenient we can now create a script that executes this code since both username and IP address are also known.

Similarly the `scp` program which is used to transfer files between hosts using SSH can be wrapped in the same way.

For both files a template was created and the `templatefile` function was used in a `local_file` resource for both files respectively:

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

Different to the other `local_file` resources (like `known_hosts`) these need some additional arguments:
The file permission `755` needs to be set which expands to `rwxr-xr-x`, giving the owner of the file read, write and execute rights while everyone else gets read and execute rights.
This is important so that the generated script can be executed.
Additionally the `depends_on` argument is set to mark this file dependent on the `known_hosts` file.
It will only be generated after the `known_hosts` file has been generated and respectively will be destroyed before the `known_hosts` file will be destroyed to ensure the depenedency chain.

The two files can now be used to transfer files between the local machine and the server and connect in a very convenient way, all without having to mess with any fingerprints again:

```
$ ./bin/scp.sh ./main.tf devops@95.216.223.223:~/test.tf
main.tf                             100% 2625    65.5KB/s   00:00
$ ./bin/ssh.sh
Linux exercise-14 6.1.0-37-amd64 #1 SMP PREEMPT_DYNAMIC Debian 6.1.140-1 (2025-05-22) x86_64
...
devops@exercise-14:~$ ls
test.tf
devops@exercise-14:~$
```

== Exercise 15: Partitions and mounting

To add a volume into the Terraform configuration a `hcloud_volume` resource is created.
When the `server_id` is specified it will be automatically attached to that server.
Alternatively a `hcloud_volume_attachment` can be used:

```tf
resource "hcloud_volume" "volume_exercise_15" {
  name      = "volume-exercise-15"
  size      = 10
  server_id = hcloud_server.exercise_15.id
  automount = true
  format    = "xfs"
}

output "volume_device" {
  description = "Linux device name of the volume"
  value       = hcloud_volume.volume_exercise_15.linux_device
}
```

The `automount` argument makes the volume being automatically mounted into the file system upon attaching it to the server.
This feature is currently broken, since it is being implemented by a `runcmd` directive in `cloud-init` which is overwritten by the custom `cloud-init` configuration provided.
To still make the automount feature available, the command used to automount is just added to the top of the `runcmd` list in the custom `cloud-init` file:

```yml
...
runcmd:
  - udevadm trigger -c add -s block -p ID_VENDOR=HC --verbose -p ID_MODEL=Volume
...
```

When connecting to the server now the mounted volume can be observed under `/dev/sdb` in the file tree.
The name output by Terraform says the volume is named `/dev/disk/by-id/scsi-0HC_Volume_102984619`.
Linux by default has all of the disks connected to the system available under `/dev`.
Each disk and partition connected has a so called "block special file" or "block device file" that refers to the block device.
`/dev/sda`, `/dev/sdb`, ... are just naming conventions for the different disk's block files.
The file name given by Hetzner to the created volume (`linux_device`) is static.

The connection between these two is that the `linux_device` name (`/dev/disk/by-id/scsi-0HC_Volume_102984619`) is a symlink to the actual block file (`/dev/sdb`) of the volume.
This means that if the location of the file were to change (when attaching more volumes for example) the same volume may not be reachable under `/dev/sdb` anymore but under `/dev/sdc` for example.
But the `linux_device` path `/dev/disk/by-id/scsi-0HC_Volume_102984619` would still be the same and not change regardless of the actual file location:

```
$ df -h
Filesystem      Size  Used Avail Use% Mounted on
...
/dev/sdb         10G  104M  9.9G   2% /mnt/HC_Volume_102984619

$ ls -l /dev/disk/by-id/
total 0
lrwxrwxrwx 1 root root  9 Jul 29 15:59 ata-QEMU_DVD-ROM_QM00001 -> ../../sr0
lrwxrwxrwx 1 root root  9 Jul 29 15:59 scsi-0HC_Volume_102984619 -> ../../sdb
...
```

=== Unmounting the Volume

As can be seen in the output of the `df` command above the volume is mounted under `/mnt/HC_Volume_102984619`.
When trying to unmount the volume while being inside of it the unmounting fails with a `target is busy` message which seems reasonable since we are currently using the disk:

```
devops@exercise-15:/$ cd /mnt/HC_Volume_102984619/
devops@exercise-15:/mnt/HC_Volume_102984619$ sudo umount /mnt/HC_Volume_102984619
umount: /mnt/HC_Volume_102984619: target is busy.
```

When leaving the mounted volume and trying to unmount again the operation is successful.
Since there is no one using the device anymore it is no longer blocked and can be unmounted.
If also won't show up in the list of file systems:

```
devops@exercise-15:/$ sudo umount /mnt/HC_Volume_102984619
devops@exercise-15:/$ df -h
Filesystem      Size  Used Avail Use% Mounted on
udev            938M     0  938M   0% /dev
tmpfs           192M  680K  192M   1% /run
/dev/sda1        38G  1.6G   35G   5% /
tmpfs           960M     0  960M   0% /dev/shm
tmpfs           5.0M     0  5.0M   0% /run/lock
/dev/sda15      241M  138K  241M   1% /boot/efi
tmpfs           192M     0  192M   0% /run/user/1000
```

=== Partitioning the Volume

To partition the volume `fdisk` is used.
`fdisk` is an interactive program to create and manipulate partitions.
To modify the `/dev/sdb` device where the disk is currently attached ```bash sudo fdisk /dev/sdb``` is used.

Since the new volume is not partitioned yet a partition table needs to be created.
We can confirm that the device is not partitioned yet with the command `F` which lists unpartitioned space:

```
Command (m for help): F

Unpartitioned space /dev/sdb: 10 GiB, 10736352768 bytes, 20969439 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes

Start      End  Sectors Size
 2048 20971486 20969439  10G
```

With `g` a new GPT partition table is created.
We can now add new partitions to the disk with the command `n`.
For each partition the partition number, the start (_first sector_) and the end (_last sector_) need to be specified.
With `+5G` we can make the last sector automatically be at around 5 GB after the start sector, splitting the disk in about half:

```
Command (m for help): g
Created a new GPT disklabel (GUID: 63C1C8E4-1B4F-7E45-8FF3-E02FD3EDDEF2).
The device contains 'xfs' signature and it will be removed by a write command. See fdisk(8) man page and --wipe option for more details.

Command (m for help): n
Partition number (1-128, default 1): 1
First sector (2048-20971486, default 2048):
Last sector, +/-sectors or +/-size{K,M,G,T,P} (2048-20971486, default 20969471): +5G

Created a new partition 1 of type 'Linux filesystem' and of size 5 GiB.

Command (m for help): n
Partition number (2-128, default 2):
First sector (10487808-20971486, default 10487808):
Last sector, +/-sectors or +/-size{K,M,G,T,P} (10487808-20971486, default 20969471):

Created a new partition 2 of type 'Linux filesystem' and of size 5 GiB.
```

We can inspect and confirm the partitions created by using the `p` command to display the partition table before committing the changes using `w`:

```
Command (m for help): p
...

Device        Start      End  Sectors Size Type
/dev/sdb1      2048 10487807 10485760   5G Linux filesystem
/dev/sdb2  10487808 20969471 10481664   5G Linux filesystem

Command (m for help): w
The partition table has been altered.
Calling ioctl() to re-read partition table.
Syncing disks.
```

Both partitions created are currently just empty.
In order to actually be able to use them to save files, a file system must be initialized on them.
The `ext4` file system is used on the first partition while `xfs` is used on the second one:

```
$ sudo mkfs -t ext4 /dev/sdb1
...
Writing superblocks and filesystem accounting information: done

devops@exercise-15:/$ sudo mkfs -t xfs /dev/sdb2
...
Discarding blocks...Done.
```

Right now those file systems are not mounted to the current file system of the server.
In order to do that mounting points (`/disk1` and `/disk2`) have to be created and then partitions can be mounted to that location.
File systems can be mounted using both the partition's block file as well as the identfier:

```
devops@exercise-15:/$ sudo blkid
...
/dev/sdb2: UUID="2a2be3e2-3b0c-4370-980b-0113c6faa901" BLOCK_SIZE="512" TYPE="xfs" PARTUUID="833b533a-10eb-8245-8e31-a0da5e13d93a"
...

devops@exercise-15:/$ sudo mount /dev/sdb1 /disk1
devops@exercise-15:/$ sudo mount UUID=2a2be3e2-3b0c-4370-980b-0113c6faa901 /disk2

devops@exercise-15:/$ df -h
Filesystem      Size  Used Avail Use% Mounted on
...
/dev/sdb1       4.9G   24K  4.6G   1% /disk1
/dev/sdb2       5.0G   68M  4.9G   2% /disk2
```

When unmounting a file system from the main file system all it's content becomes unavailable:

```
devops@exercise-15:/disk1$ sudo touch test
devops@exercise-15:/disk1$ ls
lost+found  test

devops@exercise-15:/disk1$ cd ..
devops@exercise-15:/$ sudo umount /disk1
devops@exercise-15:/$ sudo umount /disk2

devops@exercise-15:/$ cd /disk1
devops@exercise-15:/disk1$ ls
devops@exercise-15:/disk1$
```

=== Making Mounts Permanent

The file `/etc/fstab` contains information about mountable file systems in the system.
Every line in the file represents a file system that can be mounted and is a list of six whitespace-separated fields.

The first field is the specification of the file system to be mounted.
It can be the name of the block device file, a UUID or other values.
In case of the first file system it would be `/dev/sdb1`, for the second `UUID=2a2be3e2-3b0c-4370-980b-0113c6faa901`.
It is usually better to specify the UUID of the file system since as explored earlier the block file may change and then invalidate the `fstab` file.

The second field is the target path in the root file system.
These are `/disk1` and `/disk2` respectively.

The third field contains the type of file system of the mounted file system. It is `ext4` and `xfs`.

The fourth field contains mout options.
There it can be specified how and when the file system should be mounted.
Since we want the file systems to be mounted on boot, the `auto` option is used to indicate that.
It is also a good idea to at least specify the `defaults` option which also applies a prediefined, kernel-specific set of options.
Additional options will override those defaults.

The fifth field is connected to the dumping of file systems. `0` means no dubping which is the used option.

The sixth field contains the order in which the file systems are checked by `fsck`.
A value of `0` excludes the file system from such a check, a value of `1` should only be used for the root file system and a value of `2` (which has been chosen) for the rest.

The two `/etc/fstab` entries for the two file system mounts now look like this:

```
/dev/sdb1                                  /disk1  ext4  auto,defaults  0  2
UUID=2a2be3e2-3b0c-4370-980b-0113c6faa901  /disk2  xfs   auto,defaults  0  2
```

After a reboot both file systems are mounted:

```
devops@exercise-15:/$ sudo reboot
Broadcast message from root@exercise-15 on pts/1 (Tue 2025-07-29 17:27:10 UTC):
The system will reboot now!

...

devops@exercise-15:~$ df -h
Filesystem      Size  Used Avail Use% Mounted on
...
/dev/sdb1       4.9G   24K  4.6G   1% /disk1
/dev/sdb2       5.0G   68M  4.9G   2% /disk2
```

== Exercise 16: Mount point's name specification

Instead of handling the mount of the disks manually and using automounted volumes the mounting can also be done manually.
This results in much more control over the mounting process than when using automount.

The process is largely the same as in the previous exercise but done automatically.
To make the architecture configuration more customizable two new variables are introduced: `location` and `volume_mount`.

```tf
variable "volume_mount" {
  description = "Mounting point of the volume in the root file system"
  type        = string
  default     = "volume01"
}

variable "location" {
  description = "Hetzner datacenter location to create the main resources in"
  type        = string
  default     = "hel1"
  validation {
    condition     = contains(["fsn1", "nbg1", "hel1", "ash", "hil", "sin"], var.location)
    error_message = "The location must be a valid datacenter"
  }
}
```

`location` is used to control the datacenter of both the server and the volume.
Without specifying a common datacenter the volume and the server may be created in datacenters to Hetzners discretion.
They will want the created architecture to be always balanced so if one datacenter has a high capacity of volumes, new volumes will more likely be created there if no explicit location is specified.
This problem was not occurring when automounting was enabled since the volume was directly attached to a server.
To ensure valid values are used a custom validation is added to the `location` variable to ensure the value specified is one of #link("https://docs.hetzner.com/cloud/general/locations/#what-locations-are-there")[Hetzner's datacenters].

The `volume_mount` variable is used to specify the mounting path of the attached volume in the root file system.
It is used by the `cloud-init` script to create and mount at the correct location.

Since the volume creation is now decoupled from the server creation the architecture has to be modified:

```tf
resource "hcloud_volume" "volume_exercise_16" {
  name     = "volume-exercise-16"
  size     = 10
  location = var.location
  format   = "xfs"
}

resource "hcloud_server" "exercise_16" {
  name        = "exercise-16"
  image       = "debian-12"
  server_type = "cpx11"
  location    = var.location
  user_data   = local_file.cloud_init.content
}

resource "hcloud_volume_attachment" "exercise_volume_attachment" {
  volume_id = hcloud_volume.volume_exercise_16.id
  server_id = hcloud_server.exercise_16.id
  automount = false
  lifecycle {
    replace_triggered_by = [hcloud_server.exercise_16, hcloud_volume.volume_exercise_16]
  }
}
```

The `cloud-init` script is now responsible for mounting the volume to the correct location on the server.
For that the entry in `/etc/fstab` has to be created and then the mount has to be triggered via `mount -a`:

```yml
runcmd:
  ...
  - mkdir /${volume_mount}
  - echo ${volume_device} /${volume_mount} xfs auto,rw,defaults 0 2 >> /etc/fstab
  - systemctl daemon-reload
  - mount -a
  ...
```

When trying this out the resulting file system was usually not mounted.
This could be because the `mount -a` command is executed too early, resulting in some other processes to still be busy with the changes made to the mounting system.
It may also be possible that the volume attachment used to attach the volume to the server takes longer than expected.
It is being created after the creation of both server and volume which would make it a likely failure point.

To resolve this issue the call to `mount -a` has been moved to the end of the `runcmd` section after a `sleep`, giving the system enough time to settle before mounting the volume:

```yml
runcmd:
  ...
  - mkdir /${volume_mount}
  - echo ${volume_device} /${volume_mount} xfs auto,rw,defaults 0 2 >> /etc/fstab
  - systemctl daemon-reload
  ...
  - sleep 5
  - mount -a
```

Now the volume can correctly be found in the file system after creation of the server:

```
$ ./bin/ssh.sh
...
devops@exercise-16:~$ df -h
...
/dev/sdb         10G  104M  9.9G   2% /disk
```




