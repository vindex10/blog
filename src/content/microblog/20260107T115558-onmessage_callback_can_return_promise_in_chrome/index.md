---
date: '2026-01-07T11:55:58.724000'
tags:
- itnuts
title: onMessage callback can return Promise in Chrome
---

I enjoy following threads on bug trackers, here is one that got fixed recently :)

this was possible in FF but not in Chrome until recently.

```
  chrome.runtime.onMessage.addListener(async (msg) => {
    const res = await someAsyncFunction();
    return res;
  });
```

https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/API/runtime/onMessage

https://issues.chromium.org/issues/40753031

https://github.com/w3c/webextensions/issues/338
