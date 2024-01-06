---
title: Bash double quotes lesson
date: 2023-12-08T12:03:53+01:00
tags:
  - itnuts
---
#itnuts

This is the correct way to nest the double quotes in the subshell

```
a="$(command "$arg")"
```

> Using `$()` creates a new quoting context. Thus, double quotes inside a command substitution are completely independent of those outside it...

https://stackoverflow.com/questions/42652185/how-to-quote-nested-sub-shell-arguments-correctly
