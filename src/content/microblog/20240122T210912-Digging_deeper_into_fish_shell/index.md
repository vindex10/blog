---
title: Digging deeper into fish shell
date: 2024-01-22T21:09:12.350000
tags:
  - itnuts
---

I discovered that in [fish](https://fishshell.com/), process substitution `<()` works via temporary files, and `>()` is not supported at all *(maybe because it look like fish?)*

Relevant discussion since 2014, and still active now:
https://github.com/fish-shell/fish-shell/issues/1786
