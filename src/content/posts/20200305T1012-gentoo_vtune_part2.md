---
title: Installing intel vtune profiler on Gentoo. Part 2 (GUI)
date: 2020-03-05T10:12:00+02:00
tags:
    - gentoo
---
Previous post: [Installing intel vtune profiler on Gentoo]({{< ref "20200302T1750-gentoo_vtune.md" >}})

In the previous post we learned how to install CLI version of `vtune`. The thing is that CLI version is useless without
GUI to interpret results. So below we show how to make the latter work on Gentoo.

## TL;DR

* Mock `dpkg-query` to react on queries for `dpkg`, `gtk3`, `libxss`, `libnss` and `libc6`.
Make sure it is accessible from PATH. [Example](#dpkg-query-mock)

Optional:
* Replace `/etc/issue` with the one containing Debian signature. [Example](#etc-issue)
* Add `/etc/debian_version` to your system. Conatains only the version number. [Example](#debian-version)

This will trick `vtune` installer and make the installation pass. See [Alternative ways](#alternative-ways) to pick up
the hack you prefer :)

For those who would like to follow entire trip, welcome under the cut.

## What's the problem?

If you run the installer, after few steps you encounter the several errors:

```
Missing optional prerequisites
-- Intel sampling driver requires root access to installation.
-- Unsupported OS
-- GTK3 library is not found
-- Xorg X11 libXss runtime library is not found
-- Cannot detect glibc library
```

Critical ones are requirements:

* `gtk3`, which is `x11-libs/gtk+-3*` in Gentoo (my version `x11-libs/gtk+-3.24.13`)
* `libXss`, which is `x11-libs/libXScrnSaver` in Gentoo (my version `x11-libs/libXScrnSaver-1.2.3`)
* `glibc`, which is `sys-libs/glibc` in Gentoo (my version `sys-libs/glibc-2.29-r7`)

and few more you want to make sure you have, you will be warned about them when we trick installer about those 3 above:

* `libnss`, which is `dev-libs/nss` in Gentoo (my version `dev-libs/nss-3.47.1-r1`)
* `cpio`, which is `app-arch/cpio` in Gentoo (my version `app-arch/cpio-2.12-r1`)

So when requirements are fulfilled, you still will get the requirements warning, and GUI installation won't work. We will
use `strace` to find out how the installer checks for dependencies, since setting `LD_LIBRARY_PATH` or explicit symlinking doesn't help.

So let's run `install.sh` again, but under `strace` (no need for `root`, strace calls binary as a child process, thus has access to its system calls):

```bash
strace -o install.log -f ./install.sh
```

* `-o install.log` is used to direct output of strace to file.
* `-f` is used to make strace catch syscalls of child processes and threads (`install.sh` calls binary installer under the hood)

Accept terms of use and decide whether you give your concent for sharing data with Intel. After you've got the same error again, quit
the installer. Let's investigate log now.

```
# cat install.log | grep dpkg-query

23265 stat("/usr/local/sbin/dpkg-query", 0x7ffd4e1986a0) = -1 ENOENT (No such file or directory)
23265 stat("/usr/local/bin/dpkg-query", 0x7ffd4e1986a0) = -1 ENOENT (No such file or directory)
23265 stat("/usr/sbin/dpkg-query", 0x7ffd4e1986a0) = -1 ENOENT (No such file or directory)
23265 stat("/usr/bin/dpkg-query", 0x7ffd4e1986a0) = -1 ENOENT (No such file or directory)
23265 stat("/sbin/dpkg-query", 0x7ffd4e1986a0) = -1 ENOENT (No such file or directory)
23265 stat("/bin/dpkg-query", 0x7ffd4e1986a0) = -1 ENOENT (No such file or directory)
23265 stat("/opt/bin/dpkg-query", 0x7ffd4e1986a0) = -1 ENOENT (No such file or directory)
23263 write(1, "CHECK_DPKG: dpkg-query tool is '"..., 34) = 34
```

We notice that `dpkg-query` is the tool used by the installer to check dependencies. Let's create a dummy <a id="dpkg-query-mock" name="dpkg-query-mock">`dpkg-query`</a>
and put it in the one of the locations checked by the installer. Let's return some high enough version tag, just in case :)

```bash
#!/bin/bash

echo "100.100.100"
```

Remember to give it `chmod +x`, and let's run the installer:

```
Missing optional prerequisites
-- Intel sampling driver requires root access to installation.
-- Unsupported OS
```

We made it!

## Unsupported OS (fun)

When I followed this way for the first time, I had to run the installer from Docker so I had an opportunity to dig
`strace` output for OS checks. Here is what I've discovered running on Debian and search for `debian` keyword with `less`:

```bash
# cat install.log | less
522   openat(AT_FDCWD, "/etc/asianux-release", O_RDONLY) = -1 ENOENT (No such file or directory)
522   openat(AT_FDCWD, "/etc/asianux-release", O_RDONLY) = -1 ENOENT (No such file or directory)
522   openat(AT_FDCWD, "/etc/asianux-release", O_RDONLY) = -1 ENOENT (No such file or directory)
522   openat(AT_FDCWD, "/etc/caos-release", O_RDONLY) = -1 ENOENT (No such file or directory)
522   openat(AT_FDCWD, "/etc/redhat-release", O_RDONLY) = -1 ENOENT (No such file or directory)
522   openat(AT_FDCWD, "/etc/redhat-release", O_RDONLY) = -1 ENOENT (No such file or directory)
522   openat(AT_FDCWD, "/etc/redhat-release", O_RDONLY) = -1 ENOENT (No such file or directory)
522   openat(AT_FDCWD, "/etc/redhat-release", O_RDONLY) = -1 ENOENT (No such file or directory)
522   openat(AT_FDCWD, "/etc/redhat-release", O_RDONLY) = -1 ENOENT (No such file or directory)
522   openat(AT_FDCWD, "/etc/debian_version", O_RDONLY) = 18
```

Nice, so we should mock <a id="debian-version" name="debian-version">`/etc/debian_version`</a>:

```bash
# cat /etc/debian_version
10.3
```

But it turned out that `debian_version` is not enough, and you **also** need another file. Right after `debian_version`
in the `install.log` we discover check for `/etc/issue`:

```bash
# cat install.log | less
522   openat(AT_FDCWD, "/etc/debian_version", O_RDONLY) = 18
522   fstat(18, {st_mode=S_IFREG|0644, st_size=5, ...}) = 0
522   fstat(18, {st_mode=S_IFREG|0644, st_size=5, ...}) = 0
522   lseek(18, 0, SEEK_SET)            = 0
522   read(18, "10.3\n", 5)             = 5
522   lseek(18, 5, SEEK_SET)            = 5
522   close(18)                         = 0
522   openat(AT_FDCWD, "/etc/issue", O_RDONLY) = 18
522   fstat(18, {st_mode=S_IFREG|0644, st_size=27, ...}) = 0
522   fstat(18, {st_mode=S_IFREG|0644, st_size=27, ...}) = 0
522   lseek(18, 0, SEEK_SET)            = 0
522   read(18, "Debian GNU/Linux 10 \n \l\n\n", 27) = 27
522   lseek(18, 27, SEEK_SET)           = 27
```

Great, let's mock it too. Here is an example of <a id="etc-issue" name="etc-issue">`/etc/issue`</a>:

```bash
# cat /etc/issue
Debian GNU/Linux 10 \n \l

```

Notice extra newline at the end of file. You most probably have this file at your `/etc`, so you can back it up and use
as a template.

After mocking `/etc/debian_version` and `/etc/issue`, "Unsupported OS" error is gone. Congratulations!

## Alternative ways

### Docker

Just run docker with debian/ubuntu and use vtune from there. Might be an exercise to make GUI worked from Docker with X11 and xhost auth.

### PTrace (runtime hacking)

It was a fun journey to `strace` and linux syscalls. Here is an alternative path, which is definitely overkill for this setup.

`strace` tool is based on linux `ptrace` functionality. Ptrace allows you to interrupt syscalls of the child processes and
and even mutate their parameters. In this way you can wrap the installer with `ptrace` tracer and replace calls to `openat`
for mocked files, and also `execve` for `dpkg-query` calls.

* [Ptrace overview and a short tutorial with code snippets by Chris Wellons](https://nullprogram.com/blog/2018/06/23/)
* [Ptrace based snippet to override filepaths of the binary (works with open but not openat)](https://github.com/alfonsosanchezbeato/ptrace-redirect)
