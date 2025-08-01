# Exercise 2: Server re-creation

## Documentation

The server `exercise-02` with the same configuration as the one from
[Exercise 1](./exercise01.md) has been created. Additionally the same IP
addresses have been reused.

When connecting to the server now using `ssh root@46.62.163.84` the following error message appears:

```txt
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

## Explanation

This message is happens because the identity associated with the host
`46.62.163.84` inside the `known_hosts` file **differs** from the key the
server has provided now. As soon as a known host provides a different
identity, this error message occurs and warns the user from possible
**security implications**. There is usually two reasons for such a scenario,
both of which are listed in the error message:

The first possibility is that the host changed its identity for some
reason by exchanging the SSH key pair for a different one (for example
if the private key of the server gets compromised).

The second possibility and the possibility experienced now is that a new
server is using the same hostname. In this specific case it is not
security relevant since there is no relevant data on the created servers
but the new server that is serving on the same host could also be a man
in the middle server that is pretending to be the old service. In such a
case it could read all the data that would usually be transmitted
including sensitive information that `ssh` is built to handle. This is
why it is very important to **mistrust servers** should such messages appear
when connecting and double check if possible.

## Solution

Since it is known that the change in this case stems from a new server
being created replacing the old one at the same IP this warning can be
disregarded as a normal occurence. To fix the error message the
offending entries in the `known_hosts` file have to be **removed** either
manually or using the command provided by the error message: `ssh-keygen -f '~/.ssh/known_hosts' -R '46.62.163.84'` After that the host `46.62.163.84` is no longer associated with the
identity of the old server and the connection to the new server can be
established normally.
