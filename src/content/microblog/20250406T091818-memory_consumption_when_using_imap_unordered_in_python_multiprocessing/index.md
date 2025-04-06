---
date: '2025-04-06T09:18:18.845000'
tags:
- itnuts
title: memory consumption when using imap_unordered in Python multiprocessing
---

A separate thread is spawned to ingest data into the pool, but it doesn't stop to wait until the tasks are processed.
Therefore, if task definitions consume substantial amount of memory it can lead to OOM kill.

> If you're using `multiprocessing.Pool`, consider upgrading to `concurrent.futures.process.ProcessPoolExecutor`, because it handles [killed workers](https://stackoverflow.com/q/61492362/4794) better. It doesn't affect the problem described in this question.

https://stackoverflow.com/questions/40922526/memory-usage-steadily-growing-for-multiprocessing-pool-imap-unordered

