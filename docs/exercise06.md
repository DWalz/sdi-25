# Exercise 6: ssh host hopping

Two Debian 12 servers named `host-a` and `host-b` were created via the
Hetzner Cloud console. Both servers were configured with the same public
SSH key to allow access from the local workstation.

`host-a` has both the public IPv4 `65.21.182.46` and is part of a
private network with the IP `10.0.0.2`. `host-b` has only a private IPv4
and is also part of the same private network with the IP `10.0.0.3`.

On the local workstation, the private SSH key is loaded into the SSH
agent using: `ssh-add ~/.ssh/id_ed25519` Then with the agent forwarding active a SSH connection is established: `ssh -A root@65.21.182.46` From `host-a` a second SSH connection is started to `host-b` using its
private IP: `ssh root@10.0.0.3` After logging out of both hosts, the connection sequence is repeated in
the same order, first `host-a` then `host-b`. While logged inot
`host-b`, an attempt is made to open a SSH connecetion into host-a. This
results in a password prompt, despite agent forwarding being enabled on
the inital workstation connection.

Exit from `host-b` to then restart the connection from `host-a` to
`host-b` this time using agent forwarding a second time: `ssh -A root@10.0.0.2` Now when logged into `host-b` and conneceting back to `host-a`, no
password prompt appears and the login is successfull.

## Explanation

SSH agent forwarding allows the credentials of a local workstation to be
securly forwarded to remote machines. This enables indirect
authentication which means a user on `host-a` can prove his identity to
`host-b` using the agent running on the original workstation without
storing keys on any server.

However agent forwarding is not transitive by default. If `host-a`
connects to `host-b` without forwaring its own agent (`-A`), then
`host-b` has no access to the forwaded credentials and cannot connect
back to `host-a` without prompting for a password.
