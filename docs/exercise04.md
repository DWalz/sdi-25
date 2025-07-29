# Exercise 4: `ssh-agent` installation

`ssh-agent` has been installed on the local system. Now every first time
a login session needs to use the private key to establish connections
the agent asks for the passphrase of the active key. Every following
request is then answered by the ssh-agent alleviating the user of the
need to enter the passphrase every time it has to be used by the SSH
client.

This can also be combined with the
[`keychain`](https://github.com/funtoo/keychain) package to further
reduce the need to enter the passphrase to once every system reboot.
