# Exercise 10: Using the `tail -f` Command

Using the same server as [Exercise 8](./exercise08.md) with the following IP: 157.180.78.16.

On Debian 12, the `/var/log/auth.log` file is **not available** by default because they use **`journald`** for system logging.
To monitor SSH login events in real-time, the following command was used:

```txt
sudo journalctl -f -u ssh
```

This shows a **live log** of the entries related specifically to the SSH service (`-u ssh`).

A separate terminal window was used to connect to the server via SSH.
As expected, new entries appeared immediately in the journal output, logging the new session.

After a few minutes of observation, new login attempts were recorded without us initiating a new connection.
These attempts were clearly unrelated to any of our active sessions and are likely **automated brute-force attacks** from external sources.
Example log output:

```txt
Jul 28 15:21:42 indexsearch sshd[2625]: pam_unix(sshd:auth): authentication failure; logname= uid=0 euid=0 tty=ssh ruser= rhost=36.67.70.198  user=root
Jul 28 15:21:43 indexsearch sshd[2623]: Received disconnect from 157.180.78.16 port 59158:11: Bye Bye [preauth]
Jul 28 15:21:43 indexsearch sshd[2623]: Disconnected from authenticating user root 157.180.78.16 port 59158 [preauth]
Jul 28 15:21:44 indexsearch sshd[2625]: Failed password for root from 157.180.78.16 port 49436 ssh2
Jul 28 15:21:45 indexsearch sshd[2625]: Received disconnect from 157.180.78.16 port 49436:11: Bye Bye [preauth]
Jul 28 15:21:45 indexsearch sshd[2625]: Disconnected from authenticating user root 157.180.78.16 port 49436 [preauth]
```

## Explanation

The `journalctl` command provides access to all system logs managed by `systemd`.
By filtering with `-u ssh`, only logs from the SSH daemon (`sshd`) are displayed, which is ideal for monitoring login events.

The observed log entries indicate repeated failed login attempts from unknown IPs, which are likely the result of **automated scans** or **brute-force attacks** on port 22.
This is a common occurrence for publicly accessible servers and shows the importance of:

* Disabling password authentication
* Using SSH keys only
