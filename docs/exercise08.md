# Exercise 8: ssh X11 forwarding

The server `exercise-08` was created with the same configurations as the
final one from [Exercise 3](./exercise03.md).

To enable remote graphical access, the following packages were needed:

```
apt install -y firefox xauth
```

After the installation, the SSH connection was closed.
Then server was accessed again from the local workstation using **X11 forwarding**:

```
ssh -Y 157.180.78.16
```

Once logged in, the Firefox browser was started on the remote machine using:

```
firefox &
```

The Firefox window appeared **locally** on the workstation desktop.
Within Firefox navigating to:

```
http://localhost
```

This will show the welcome page of Nginx confirming that the browser running on the server could access the local Nginx service.

## Explanation

X11 forwarding allows GUI applications from a remote Linux system shown displayed on a local machine.
The `-Y` flag tells SSH to securely forward X11 traffic, enabling programs like Firefox to run remotely but render locally.

**Note for macOS and Windows:**
X11 support requires an external X server (XQuartz on macOS or VcXsrv/Xming on Windows).

This setup allows secure remote GUI access without exposing services like Nginx to the public.



