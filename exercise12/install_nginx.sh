#!/bin/sh
# Update installation
apt-get update
apt-get -y upgrade

# Install nginx
apt-get -y install nginx

# Start and enable (survive after re-boot) nginx
systemctl start nginx
systemctl enable nginx
