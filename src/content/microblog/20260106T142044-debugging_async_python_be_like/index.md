---
date: '2026-01-06T14:20:44.041000'
tags:
- itnuts
title: debugging async python be like
---

```
while True:
    breakpoint()
    await asyncio.sleep(1)
```

re-enter into debugger after giving asyncio time to execute tasks.

Other discussions:

* https://discuss.python.org/t/could-we-give-pdb-a-better-awaitable-story/63704
* https://github.com/aio-libs/aiomonitor (based on aioconsole)
* https://aioconsole.readthedocs.io/en/latest/
