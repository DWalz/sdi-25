# Exercise 3: Improve your server’s security

A firewall with the name `fw-exercise-03` has been created with a single
inbound rule for [**ICMP**](https://en.wikipedia.org/wiki/Internet_Control_Message_Protocol) traffic. The server `exercise-03` has been
created using the new firewall and the same procedure as the previous
exercises.
The server IP for `exercise-03` is `46.62.163.84`.

Pinging the server with `ping 46.62.163.84` results in successful ping answers but trying to connect using `ssh root@46.62.163.84` results in a timeout.

## Firewalls and SSH

Firewalls work on a whitelist principle. This means that as soon as a
firewall is applied **all traffic is forbidden** except the traffic allowed
by the firewall’s rules. Currently the firewall limits incoming traffic
to use the **ICMP** protocol which is used to exchange operation
information (for example the “alive-ness” when using `ping`) which
results in traffic using the **TCP** protocol (and any other protocol)
to be blocked. SSH is using **TCP** on port `22` and is therefor
blocked.

After adding an inbound **TCP** rule on port `22` both `ping` and `ssh`
access are successful.

## Nginx Installation

The server was updated and rebooted. After the reboot `nginx` has been
installed and the status of the `nginx` service has been confirmed:

```txt
# systemctl status nginx
● nginx.service - A high performance web server and a reverse proxy server
      Loaded: loaded (/lib/systemd/system/nginx.service; enabled; preset: enabled)
      Active: active (running) since Mon 2025-07-21 12:03:09 UTC; 10s ago
      ...
```

**Nginx** is a server application that is used to host websites and
other web services. The websites served by **nginx** are by default
accessed using the HTTP protocol which is served via TCP on port `80`.
The command `wget` can be used to access the content of the default
generated website served by `nginx`:

```+
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

## Nginx & Firewall

When trying to get the file from the local computer the connection fails
with a timeout similarly to the **SSH** case before. The firewall once again
blocks all incoming traffic that is not whitelisted by a firewall rule.
Since **HTTP** used **TCP** over port 80 the current firewall setup blocks the
incoming **HTTP** traffic.

Since the firewall sits between the server and the internet, requests
can be made from the server to itself. The firewall would block such
traffic were it to receive it but since it is just routed using the
loopback interface of the server it will not reach any other network
interface other than the server itself.

After an inbound rule for TCP port `80` is added the website can be
accessed from outside too.

```txt
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
