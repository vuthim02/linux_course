## 🧠 Deep Understanding — How Search Tools Work

### grep Internals

When you run `grep "pattern" file.txt`:

```
1. grep opens file.txt
2. Reads one line at a time into memory
3. Compiles the regex pattern into an internal state machine
4. For each line: runs the state machine against the characters
5. If match found: prints the line
6. Continues until EOF

Why grep is fast: it processes lines sequentially (no random access),
and the Boyer-Moore algorithm skips ahead when possible.
```

### The Locate Database

```
updatedb reads the entire filesystem tree and stores:
  - File paths
  - Permissions (for security — root files are hidden from normal users)
  
Database location: /var/lib/mlocate/mlocate.db
Update schedule: daily via /etc/cron.daily/mlocate

Why locate is instant: it searches a sorted database using binary search (O(log n))
```

### The find Algorithm

```
find traverses the directory tree using readdir() for each directory.
For each entry, it applies your test conditions in order.
If all conditions pass, it performs the action.

Performance tip: put the cheapest tests first
  - Type check (-type f) is very fast
  - Size check (-size) requires stat() call (slower)
  - Content check (-exec grep) requires opening file (slowest)

So: find . -type f -name "*.log" -size +10M
Better than: find . -size +10M -name "*.log" -type f
```

### Why grep -r Can Be Slow (and How to Fix It)

```
grep -r opens EVERY file, including binary files.
Speed tips:
  grep -r --include="*.log" "pattern"   # Only .log files
  grep -r --exclude="*.bin" "pattern"   # Skip binaries
  rg "pattern"                           # ripgrep is smarter
```

---



---

[← Previous](09-practice-section-18-hands-on-exercises.md) | [↑ Index](index.md) | [Next →](11-summary-complete-command-reference-for.md)
