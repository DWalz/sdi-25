# Exercise 15: Partitions and mounting

To add a volume into the Terraform configuration a `hcloud_volume`
resource is created. When the `server_id` is specified it will be
automatically attached to that server. Alternatively a
`hcloud_volume_attachment` can be used:

```tf
resource "hcloud_volume" "volume_exercise_15" {
  name      = "volume-exercise-15"
  size      = 10
  server_id = hcloud_server.exercise_15.id
  automount = true
  format    = "xfs"
}

output "volume_device" {
  description = "Linux device name of the volume"
  value       = hcloud_volume.volume_exercise_15.linux_device
}
```

The `automount` argument makes the volume being automatically mounted
into the file system upon attaching it to the server. This feature is
currently broken, since it is being implemented by a `runcmd` directive
in `cloud-init` which is overwritten by the custom `cloud-init`
configuration provided. To still make the automount feature available,
the command used to automount is just added to the top of the `runcmd`
list in the custom `cloud-init` file:

```yml
...
runcmd:
  - udevadm trigger -c add -s block -p ID_VENDOR=HC --verbose -p ID_MODEL=Volume
...
```

When connecting to the server now the mounted volume can be observed
under `/dev/sdb` in the file tree. The name output by Terraform says the
volume is named `/dev/disk/by-id/scsi-0HC_Volume_102984619`. Linux by
default has all of the disks connected to the system available under
`/dev`. Each disk and partition connected has a so called “block special
file” or “block device file” that refers to the block device.
`/dev/sda`, `/dev/sdb`, … are just naming conventions for the different
disk’s block files. The file name given by Hetzner to the created volume
(`linux_device`) is static.

The connection between these two is that the `linux_device` name
(`/dev/disk/by-id/scsi-0HC_Volume_102984619`) is a symlink to the actual
block file (`/dev/sdb`) of the volume. This means that if the location
of the file were to change (when attaching more volumes for example) the
same volume may not be reachable under `/dev/sdb` anymore but under
`/dev/sdc` for example. But the `linux_device` path
`/dev/disk/by-id/scsi-0HC_Volume_102984619` would still be the same and
not change regardless of the actual file location:

```txt
$ df -h
Filesystem      Size  Used Avail Use% Mounted on
...
/dev/sdb         10G  104M  9.9G   2% /mnt/HC_Volume_102984619

$ ls -l /dev/disk/by-id/
total 0
lrwxrwxrwx 1 root root  9 Jul 29 15:59 ata-QEMU_DVD-ROM_QM00001 -> ../../sr0
lrwxrwxrwx 1 root root  9 Jul 29 15:59 scsi-0HC_Volume_102984619 -> ../../sdb
...
```

## Unmounting the Volume

As can be seen in the output of the `df` command above the volume is
mounted under `/mnt/HC_Volume_102984619`. When trying to unmount the
volume while being inside of it the unmounting fails with a
`target is busy` message which seems reasonable since we are currently
using the disk:

```txt
devops@exercise-15:/$ cd /mnt/HC_Volume_102984619/
devops@exercise-15:/mnt/HC_Volume_102984619$ sudo umount /mnt/HC_Volume_102984619
umount: /mnt/HC_Volume_102984619: target is busy.
```

When leaving the mounted volume and trying to unmount again the
operation is successful. Since there is no one using the device anymore
it is no longer blocked and can be unmounted. If also won’t show up in
the list of file systems:

```txt
devops@exercise-15:/$ sudo umount /mnt/HC_Volume_102984619
devops@exercise-15:/$ df -h
Filesystem      Size  Used Avail Use% Mounted on
udev            938M     0  938M   0% /dev
tmpfs           192M  680K  192M   1% /run
/dev/sda1        38G  1.6G   35G   5% /
tmpfs           960M     0  960M   0% /dev/shm
tmpfs           5.0M     0  5.0M   0% /run/lock
/dev/sda15      241M  138K  241M   1% /boot/efi
tmpfs           192M     0  192M   0% /run/user/1000
```

## Partitioning the Volume

To partition the volume `fdisk` is used. `fdisk` is an interactive
program to create and manipulate partitions. To modify the `/dev/sdb`
device where the disk is currently attached `sudo fdisk /dev/sdb` is used.

Since the new volume is not partitioned yet a partition table needs to
be created. We can confirm that the device is not partitioned yet with
the command `F` which lists unpartitioned space:

```txt
Command (m for help): F

Unpartitioned space /dev/sdb: 10 GiB, 10736352768 bytes, 20969439 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes

Start      End  Sectors Size
 2048 20971486 20969439  10G
```

With `g` a new GPT partition table is created. We can now add new
partitions to the disk with the command `n`. For each partition the
partition number, the start (*first sector*) and the end (*last sector*)
need to be specified. With `+5G` we can make the last sector
automatically be at around 5 GB after the start sector, splitting the
disk in about half:

```txt
Command (m for help): g
Created a new GPT disklabel (GUID: 63C1C8E4-1B4F-7E45-8FF3-E02FD3EDDEF2).
The device contains 'xfs' signature and it will be removed by a write command. See fdisk(8) man page and --wipe option for more details.

Command (m for help): n
Partition number (1-128, default 1): 1
First sector (2048-20971486, default 2048):
Last sector, +/-sectors or +/-size{K,M,G,T,P} (2048-20971486, default 20969471): +5G

Created a new partition 1 of type 'Linux filesystem' and of size 5 GiB.

Command (m for help): n
Partition number (2-128, default 2):
First sector (10487808-20971486, default 10487808):
Last sector, +/-sectors or +/-size{K,M,G,T,P} (10487808-20971486, default 20969471):

Created a new partition 2 of type 'Linux filesystem' and of size 5 GiB.
```

We can inspect and confirm the partitions created by using the `p`
command to display the partition table before committing the changes
using `w`:

```txt
Command (m for help): p
...

Device        Start      End  Sectors Size Type
/dev/sdb1      2048 10487807 10485760   5G Linux filesystem
/dev/sdb2  10487808 20969471 10481664   5G Linux filesystem

Command (m for help): w
The partition table has been altered.
Calling ioctl() to re-read partition table.
Syncing disks.
```

Both partitions created are currently just empty. In order to actually
be able to use them to save files, a file system must be initialized on
them. The `ext4` file system is used on the first partition while `xfs`
is used on the second one:

```txt
$ sudo mkfs -t ext4 /dev/sdb1
...
Writing superblocks and filesystem accounting information: done

devops@exercise-15:/$ sudo mkfs -t xfs /dev/sdb2
...
Discarding blocks...Done.
```

Right now those file systems are not mounted to the current file system
of the server. In order to do that mounting points (`/disk1` and
`/disk2`) have to be created and then partitions can be mounted to that
location. File systems can be mounted using both the partition’s block
file as well as the identfier:

```txt
devops@exercise-15:/$ sudo blkid
...
/dev/sdb2: UUID="2a2be3e2-3b0c-4370-980b-0113c6faa901" BLOCK_SIZE="512" TYPE="xfs" PARTUUID="833b533a-10eb-8245-8e31-a0da5e13d93a"
...

devops@exercise-15:/$ sudo mount /dev/sdb1 /disk1
devops@exercise-15:/$ sudo mount UUID=2a2be3e2-3b0c-4370-980b-0113c6faa901 /disk2

devops@exercise-15:/$ df -h
Filesystem      Size  Used Avail Use% Mounted on
...
/dev/sdb1       4.9G   24K  4.6G   1% /disk1
/dev/sdb2       5.0G   68M  4.9G   2% /disk2
```

When unmounting a file system from the main file system all it’s content
becomes unavailable:

```txt
devops@exercise-15:/disk1$ sudo touch test
devops@exercise-15:/disk1$ ls
lost+found  test

devops@exercise-15:/disk1$ cd ..
devops@exercise-15:/$ sudo umount /disk1
devops@exercise-15:/$ sudo umount /disk2

devops@exercise-15:/$ cd /disk1
devops@exercise-15:/disk1$ ls
devops@exercise-15:/disk1$
```

## Making Mounts Permanent

The file `/etc/fstab` contains information about mountable file systems
in the system. Every line in the file represents a file system that can
be mounted and is a list of six whitespace-separated fields.

The first field is the specification of the file system to be mounted.
It can be the name of the block device file, a UUID or other values. In
case of the first file system it would be `/dev/sdb1`, for the second
`UUID=2a2be3e2-3b0c-4370-980b-0113c6faa901`. It is usually better to
specify the UUID of the file system since as explored earlier the block
file may change and then invalidate the `fstab` file.

The second field is the target path in the root file system. These are
`/disk1` and `/disk2` respectively.

The third field contains the type of file system of the mounted file
system. It is `ext4` and `xfs`.

The fourth field contains mout options. There it can be specified how
and when the file system should be mounted. Since we want the file
systems to be mounted on boot, the `auto` option is used to indicate
that. It is also a good idea to at least specify the `defaults` option
which also applies a prediefined, kernel-specific set of options.
Additional options will override those defaults.

The fifth field is connected to the dumping of file systems. `0` means
no dubping which is the used option.

The sixth field contains the order in which the file systems are checked
by `fsck`. A value of `0` excludes the file system from such a check, a
value of `1` should only be used for the root file system and a value of
`2` (which has been chosen) for the rest.

The two `/etc/fstab` entries for the two file system mounts now look
like this:

```txt
/dev/sdb1                                  /disk1  ext4  auto,defaults  0  2
UUID=2a2be3e2-3b0c-4370-980b-0113c6faa901  /disk2  xfs   auto,defaults  0  2
```

After a reboot both file systems are mounted:

```txt
devops@exercise-15:/$ sudo reboot
Broadcast message from root@exercise-15 on pts/1 (Tue 2025-07-29 17:27:10 UTC):
The system will reboot now!

...

devops@exercise-15:~$ df -h
Filesystem      Size  Used Avail Use% Mounted on
...
/dev/sdb1       4.9G   24K  4.6G   1% /disk1
/dev/sdb2       5.0G   68M  4.9G   2% /disk2
```
