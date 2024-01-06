---
title: Bidirectional tcp - udp forwarding oneliner
date: 2023-08-09T22:59:39+01:00
tags:
  - itnuts
---
\#itnuts

if you ever wondered how to connect to Wireguard server via SSH:

```
mkfifo /tmp/fifo
nc -l -p 5679 < /tmp/fifo | nc -u 127.0.0.1 5678 > /tmp/fifo
```

https://superuser.com/questions/53103/udp-traffic-through-ssh-tunnel
