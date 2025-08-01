# Exercise 17: A module for ssh host key handling

> Click [here](https://github.com/DWalz/sdi-25/tree/main/exercise17) to view the solution in the repository.

Currently, the setup of the `known_hosts` file and the `ssh` and `scp` wrappers is in the main configuration.
For simpler development and more modular use it is sensible to move this encapsulated behavior to a module.
We can then call this module from multiple configurations or easily loop it to allow for multiple servers to be defined.

## Moving the File Generation to the Module

To move the functionality into a module all the template files, and `local_file` resources used to generate the `known_hosts` file and wrappers is moved into `./modules/ssh_wrapper` while the rest of the configuration is moved to `./configuration`.
In the current state the module would not work correctly, since the resources in the modules take values from the resources in the main configuration like the server IP or the SSH public key.

This information that the module needs to work as an independent, isolated Terraform module can be specified using variables.
These variables will be enforced by Terraform when calling the module.
The variables `server_username`, `server_hostname` and `server_public_key` are defined in the child module:

```tf
variable "server_username" {
  description = "Username to use for the default user on the server"
  type        = string
}

variable "server_hostname" {
  description = "Hostname to use for the default user on the server (e.g. IPv4)"
  type        = string
}

variable "server_public_key" {
  description = "The SSH public key of the server"
  type        = string
}
```

They will then be used by the resources inside the module to construct the file like in [Exercise 14](./exercise14.md) before.
The only difference is the resolution of paths.
Before, a relative path like `./gen/known_hosts` was enough to specify the location of the file.
Now `./gen/known_hosts` would generate the file in the `gen` folder of the child module, not the parent module.
Terraforms `path` resource allows us to circumvent this problem: `path.root` contains the file path to the root module, which is the main configuration:

```tf
resource "local_file" "known_hosts" {
  filename = "${path.root}/gen/known_hosts"
  content = join(" ", [
    var.server_hostname,
    var.server_public_key
  ])
  file_permission = "644"
}

resource "local_file" "ssh_bin" {
  filename = "${path.root}/bin/ssh.sh"
  ...
}

resource "local_file" "scp_bin" {
  filename = "${path.root}/bin/scp.sh"
  ...
}
```

## Specifying Paths in More Detail

The approach shown above to file paths is robust but not very flexible.
It allows the parent module little control over the location of the files, which can lead to issues.
Looking forward to [Exercise 21](./exercise21.md) for example, there will be a number of servers and therefor a number of `known_host`, `ssh` and `scp` files generated.
If the current setup were to be used, all those files would overwrite each other.

It is therefor better to give the calling module control over the location of the files.
This can be done using an input variable which contains the target paths of the files being created.
When calling the module in a loop later, this will result in each iteration being able to specify their own location separate from each other:

```tf
variable "output_dir" {
  description = "The output directory of the files; they will be generated under /gen and /bin inside this directory"
  type        = string
  default     = path.root
}
```

The parent module can now specify the file path:

```tf
module "ssh_wrapper" {
  source            = "../modules/ssh_wrapper"
  server_hostname   = hcloud_server.exercise_17.ipv4_address
  server_username   = var.server_username
  server_public_key = tls_private_key.server_ssh_key.public_key_openssh
}
```

With that the same functionality has been extracted into a module:

```
$ ./bin/ssh.sh
...
devops@exercise-17:~$
```