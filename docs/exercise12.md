# Exercise 12: Automatic Nginx installation

> Click [here](https://github.com/DWalz/sdi-25/tree/main/exercise12) to view the solution in the repository.

The following script can be used to install, start and enable (make it
survive a re-boot) the `nginx` package on the server the following
script has been created. It will update the system first `apt-get update` and `apt-get -y upgrade` and after that install Nginx and enable it using the `systemctl`:

``` bash
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

To make the script run on server start the `user_data` argument is used
to pass the file to terraform. It will be applied to the server once it
starts.

To be able to reach the webserver and test the success of installing
`nginx` the server needs a firewall that allows incoming HTTP traffic.
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

When accessing the website in the browser under `http://95.216.223.223`
the `nginx` default landing page can be observed. Even after a server
restart there is no additional commands that need to be executed on the
server to make `nginx` running again thus showing the landing page
immediately.

![`nginx` landing page](./images/nginx_landing_page.png)
