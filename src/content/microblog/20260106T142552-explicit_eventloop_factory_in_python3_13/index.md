---
date: '2026-01-06T14:25:52.014000'
tags:
- itnuts
title: explicit eventloop factory in python3.13
---

https://docs.python.org/3/library/asyncio-eventloop.html#asyncio.EventLoop

> An alias to the most efficient available subclass of [`AbstractEventLoop`](https://docs.python.org/3/library/asyncio-eventloop.html#asyncio.AbstractEventLoop "asyncio.AbstractEventLoop") for the given platform.

Before 3.13 can be implemented with:

```
import asyncio
import selectors

loop = asyncio.SelectorEventLoop(selectors.SelectSelector())
```

EventLoop came with deprecation of the policy based event loop selection: 
https://docs.python.org/3/library/asyncio-policy.html#asyncio-policies
