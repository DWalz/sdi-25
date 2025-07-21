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

=== Exercise 4: `ssh-agent` installation

`ssh-agent` has been installed on the local system.
Now every first time a login session needs to use the private key to establish connections the agent asks for the passphrase of the active key.
Every following request is then answered by the ssh-agent alleviating the user of the need to enter the passphrase every time it has to be used by the SSH client.

This can also be combined with the #link("https://github.com/funtoo/keychain")[`keychain`] package to further reduce the need to enter the passphrase to once every system reboot.

=== Exercise 5: MI Gitlab access by ssh

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
