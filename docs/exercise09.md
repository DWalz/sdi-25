# Exercise 9: Enabling index based file search

Using the same server as [Exercise 8](./exercise08.md) with the following IP 157.180.78.16.

The `plocate` package was installed to provide a file lookup mechanism using prebuilt indexes:

```
apt install -y plocate
```

To use the `locate` application first a system-wide index of all files was created using:

```
sudo updatedb
```

To test the functionality, a search was done for known system files:

```
root@exercise-09:~# locate aptitude
/etc/alternatives/aptitude
/etc/alternatives/aptitude.8.gz
/etc/alternatives/aptitude.cs.8.gz
...
```

Then a new file was created in the system using:

```
touch /root/mylocaltest.txt
```

Attempting to locate the new file immediately:

```
locate mylocaltest
```

However this returned **no results**, as the file was not yet included in the index.
So we have to rebuilding the index again:

```
sudo updatedb
```

After building the index new the file could now to be found via `locate`.

```
root@exercise-09:~# locate mylocaltest
/root/mylocaltest.txt
```

Next the file was deleted:

```
rm /root/mylocaltest.txt
```

A new `locate` call still returned the file path, since the index had not yet been updated.
Only after rebuilding the index did the file disappear from the `locate` results:

```
sudo updatedb
```

## Explanation

`plocate` relies on a periodically updated database of the file system.
It does **not track real-time changes**, meaning newly created or deleted files are not reflected until `updatedb` is rerun.

So the best way to use this would be to run scripts in fixed intervals, like on startup or before shutting down the system.
