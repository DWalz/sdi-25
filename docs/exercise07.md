# Exercise 7: SSH Port Forwarding

The server `exercise-07` was created with the same configurations as the
final one from [Exercise 3](./exercise03.md). The server has the same IP as
`host-a` from [Exercise 6](./exercise06.md).

A quick test shows that Nginx is accessible:

```txt
curl http://95.216.223.223
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
```

The firewall configuration was updated to allow only SSH (port `22`) and
block HTTP (port `80`) from public access. Attempting to access the HTTP
service from the local machine again shows:

```txt
curl -O - http://65.21.182.46
curl: (28) Failed to connect to 65.21.182.46 port 80 after 75003 ms: Couldn't connect to server
```

To test HTTP access securely, a local SSH tunnel is needed:
`ssh -L 2000:localhost:80 root@65.21.182.46 -N`
This command forwards local port 2000 on the workstation to port 80 on
the remote server through SSH. Visiting [http://localhost:2000](http://localhost:2000) in a local
browser renders the default Nginx welcome page, confirming that the HTTP service
is accessible only through the SSH tunnel.

## Explanation

SSH local port forwarding is a powerful feature that allows tunneling of
TCP connections through a secure channel. By forwarding local port 2000
to port 80 on the remote host, it becomes possible to access the remote
web server without exposing it to the public internet.

This approach is useful for secure access to internal or restricted
services without altering firewall rules.
