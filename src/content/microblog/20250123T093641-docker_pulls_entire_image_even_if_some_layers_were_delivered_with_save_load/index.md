---
date: '2025-01-23T09:36:41.871000'
tags:
- itnuts
title: Docker pulls entire image even if some layers were delivered with save/load
---

> When saving an image from the graph-driver store, a new archive is created containing the uncompressed layers; saving/loading will produce the same layers as were pulled, but the save/load won't include information about their compressed digests, because this information cannot be verified without the actual compressed artifacts (as pulled from the registry). Reconstructing the compressed layers is not possible due to compression algorithms not being 100% reproducible (they may be most of the time, but various factors, including CPU load, and CPU optimizations during compression can cause their checksum to differ).

https://github.com/moby/moby/issues/46664
