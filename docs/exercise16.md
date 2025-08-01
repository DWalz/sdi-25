# Exercise 16: Mount point’s name specification

> Click [here](https://github.com/DWalz/sdi-25/tree/main/exercise16) to view the solution in the repository.

Instead of handling the mount of the disks manually and using
automounted volumes the mounting can also be done manually. This results
in much more control over the mounting process than when using
automount.

The process is largely the same as in the previous exercise but done
automatically. To make the architecture configuration more customizable
two new variables are introduced: `location` and `volume_mount`.

```tf
variable "volume_mount" {
  description = "Mounting point of the volume in the root file system"
  type        = string
  default     = "volume01"
}

variable "location" {
  description = "Hetzner datacenter location to create the main resources in"
  type        = string
  default     = "hel1"
  validation {
    condition     = contains(["fsn1", "nbg1", "hel1", "ash", "hil", "sin"], var.location)
    error_message = "The location must be a valid datacenter"
  }
}
```

`location` is used to control the datacenter of both the server and the
volume. Without specifying a common datacenter the volume and the server
may be created in datacenters to Hetzners discretion. They will want the
created architecture to be always balanced so if one datacenter has a
high capacity of volumes, new volumes will more likely be created there
if no explicit location is specified. This problem was not occurring
when automounting was enabled since the volume was directly attached to
a server. To ensure valid values are used a custom validation is added
to the `location` variable to ensure the value specified is one of
[Hetzner’s
datacenters](https://docs.hetzner.com/cloud/general/locations/#what-locations-are-there).

The `volume_mount` variable is used to specify the mounting path of the
attached volume in the root file system. It is used by the `cloud-init`
script to create and mount at the correct location.

Since the volume creation is now decoupled from the server creation the
architecture has to be modified:

```tf
resource "hcloud_volume" "volume_exercise_16" {
  name     = "volume-exercise-16"
  size     = 10
  location = var.location
  format   = "xfs"
}

resource "hcloud_server" "exercise_16" {
  name        = "exercise-16"
  image       = "debian-12"
  server_type = "cpx11"
  location    = var.location
  user_data   = local_file.cloud_init.content
}

resource "hcloud_volume_attachment" "exercise_volume_attachment" {
  volume_id = hcloud_volume.volume_exercise_16.id
  server_id = hcloud_server.exercise_16.id
  automount = false
  lifecycle {
    replace_triggered_by = [hcloud_server.exercise_16, hcloud_volume.volume_exercise_16]
  }
}
```

The `cloud-init` script is now responsible for mounting the volume to
the correct location on the server. For that the entry in `/etc/fstab`
has to be created and then the mount has to be triggered via `mount -a`:

```yml
runcmd:
  ...
  - mkdir /${volume_mount}
  - echo ${volume_device} /${volume_mount} xfs auto,rw,defaults 0 2 >> /etc/fstab
  - systemctl daemon-reload
  - mount -a
  ...
```

When trying this out the resulting file system was usually not mounted.
This could be because the `mount -a` command is executed too early,
resulting in some other processes to still be busy with the changes made
to the mounting system. It may also be possible that the volume
attachment used to attach the volume to the server takes longer than
expected. It is being created after the creation of both server and
volume which would make it a likely failure point.

To resolve this issue the call to `mount -a` has been moved to the end
of the `runcmd` section after a `sleep`, giving the system enough time
to settle before mounting the volume:

```yml
runcmd:
  ...
  - mkdir /${volume_mount}
  - echo ${volume_device} /${volume_mount} xfs auto,rw,defaults 0 2 >> /etc/fstab
  - systemctl daemon-reload
  ...
  - sleep 5
  - mount -a
```

Now the volume can correctly be found in the file system after creation
of the server:

```txt
$ ./bin/ssh.sh
...
devops@exercise-16:~$ df -h
...
/dev/sdb         10G  104M  9.9G   2% /disk
```
