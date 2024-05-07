---
title: VPN considered insecure
date: 2024-05-07T14:59:22.655000
tags:
  - itnuts
---

https://arstechnica.com/security/2024/05/novel-attack-against-virtually-all-vpn-apps-neuters-their-entire-purpose/

general practice for VPN, is to prioritize itself via defining more specific routing rules, which take priority over the default gateway.
the attacker, however, can spin up another DHCP server, and use rule 121 to push some new routes to the client.
Importantly, if the routes are more specific than the ones defined by the VPN, they will take over, and unencrypted traffic directed to the VPN interface will end up on the attacker's machine.

the golden standard to avoid this vulnerability is using network namespaces:
https://www.wireguard.com/netns/#the-new-namespace-solution

discussion: [HN1](https://news.ycombinator.com/item?id=40284111) , [HN2](https://news.ycombinator.com/item?id=40279632)
