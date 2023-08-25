---
title: Using WSL with VPN running on the host
date: 2023-08-25T13:00:00+02:00
tags:
    - wsl
    - networking
    - linux
---

I noticed that WSL looses network connection when I turn on VPN on the host.
In my case, the issue happend for Cisco AnyConnect VPN, but from the solution, it seems,
the same may happen with any other VPN service.

There are plenty of open threads related to the issue:

* https://superuser.com/questions/1630487/no-internet-connection-ubuntu-wsl-while-vpn
* https://community.cisco.com/t5/vpn/anyconnect-wsl-2-windows-substem-for-linux/td-p/4179888
* https://jamespotz.github.io/blog/how-to-fix-wsl2-and-cisco-vpn
* https://gist.github.com/balmeida-nokia/122adf625c11c916902950e3255bd104
* https://gist.github.com/machuu/7663aa653828d81efbc2aaad6e3b1431

## 1. Lower VPN network adapter priority

Windows implements a prioritization mechanism for network devices,
and we want the VPN device to appear with lower priority than WSL routes, which by default are configured with metric value 5256.
This will fix the network connectivity but not DNS.

- _Powershell_:
    ```powershell
    Get-NetAdapter | Where-Object {$_.InterfaceDescription -Match "Cisco AnyConnect"} | Set-NetIPInterface -InterfaceMetric 6000
    ```

- _GUI_: https://www.kapilarya.com/how-to-change-the-network-connection-priority-in-windows-10

NOTE: the metric resets on reconnect, so do this change on each reconnect to VPN.
You can call this Powershell command from inside WSL, as part of the DNS script from Step 2.
It may be practical if you own admin rights for your windows user.

## 2. Configuring DNS

VPN usually routes traffic via internal DNS services.
If this is the case for you, the DNS servers in WSL should be updated and it doesn't happen automatically.

A powershell called from inside WSL can be used to extract the new DNS config:

```bash
    /mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -Command '
    $ErrorActionPreference="SilentlyContinue"
    Get-NetAdapter -InterfaceDescription "Cisco AnyConnect*" | ?{ $_.Status -eq "Up" } | Get-DnsClientServerAddress | Select -ExpandProperty ServerAddresses
    Get-NetAdapter | ?{-not ($_.InterfaceDescription -like "Cisco AnyConnect*") -and ($_.Status -eq "Up") } | Get-DnsClientServerAddress | Select -ExpandProperty ServerAddresses
    ' | \
            awk '{print "nameserver", $1}' | \
            tr -d '\r'

    /mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -Command '
    $ErrorActionPreference="SilentlyContinue"
    Get-DnsClientGlobalSetting | Select-Object -ExpandProperty SuffixSearchList
    ' | \
            awk '{print "search", $1}' | \
            tr -d '\r'
```

DNS servers, i.e. `/etc/resolv.conf`, should be changed when we switch the VPN on and off.
To avoid implementing a complex logic of parsing `resolv.conf`, I'd suggest a solution based on `resolvconf` tool.

### Prevent WSL from overwriting /etc/resolv.conf

WSL forcefully restores the symlink from `/mnt/wsl/resolv.conf` to `/etc/resolv.conf`.
We want to disable this behavior, since we want `resolv.conf` to go through `resolvconf` utility.

Edit your wsl config: `/etc/wsl.conf`. Add these lines:

```ini
[network]
generateResolvConf = false
```

Now restart WSL for changes to get into action:

```powershell
# powershell
wsl --shutdown
```

### Configuring DNS with Resolconf

Resolvconf will use `/etc/wsl/resolv.conf` as base config,
but will prepend custom DNS records which we will dynamically extract from the host.

First, install it:

```bash
apt install resolvconf
```

Resolvconf maintains its copy of resolvconf, which should be symlinked from `/etc/resolv.conf`:

```bash
mv /etc/resolv.conf /etc/resolv.conf.bak
ln -s /run/resolvconf/resolv.conf /etc/resolv.conf
```

WSL mounts a custom resolv.conf pushed from the host. We want to specify it as a base config for `resolvconf`:

```bash
ln -sf /mnt/wsl/resolv.conf /etc/resolvconf/resolv.conf.d/original.resolvconf
ln -sf /mnt/wsl/resolv.conf /etc/resolvconf/resolv.conf.d/base
```

Update head of `resolv.conf` based on the current host configuration.
You will have to run this script each time you connect/disconnect from VPN:

```bash
#!/bin/bash
set -x

function get_dns_config() {
    /mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -Command '
    $ErrorActionPreference="SilentlyContinue"
    Get-NetAdapter -InterfaceDescription "Cisco AnyConnect*" | ?{ $_.Status -eq "Up" } | Get-DnsClientServerAddress | Select -ExpandProperty ServerAddresses
    Get-NetAdapter | ?{-not ($_.InterfaceDescription -like "Cisco AnyConnect*") -and ($_.Status -eq "Up") } | Get-DnsClientServerAddress | Select -ExpandProperty ServerAddresses
    ' | \
            awk '{print "nameserver", $1}' | \
            tr -d '\r'

    /mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -Command '
    $ErrorActionPreference="SilentlyContinue"
    Get-DnsClientGlobalSetting | Select-Object -ExpandProperty SuffixSearchList
    ' | \
            awk '{print "search", $1}' | \
            tr -d '\r'
}

get_dns_config > /etc/resolvconf/resolv.conf.d/head
resolvconf -u
```

Since we plan to run it quite frequently, lets store this script to `/opt/bin/reset-vpn.sh`.
(Remember to make it executable with `chmod +x /opt/bin/reset-vpn.sh`)

This should work now, but will fail upon restart, because `resolvconf` should be called on system start.


### Startup script for resolvconf

Systemd is not enabled by default in WSL, so standard `systemctl enable resolvconf` won't work.

It is possible to enable systemd for WSL (
[Microsoft](https://devblogs.microsoft.com/commandline/systemd-support-is-now-available-in-wsl/),
[StackExchange](https://superuser.com/a/1685207)
). There is, however, a simpler way to add boot commands. Add the following to `/etc/wsl.conf`:

```init
[boot]
command = resolvconf --enable-updates; /opt/bin/reset-vpn.sh;
```

Now you are all set. Briefly:

* Try restarting WSL with `wsl --shutdown` and check that `/etc/resolv.conf` is updated.
* Then start the VPN and call `/opt/bin/reset-vpn.sh`.
* Remember to increase the network adapter metric if you didn't add this command to `reset-vpn.sh`.
* You should be able to `ping google.com`!

Cheers!
