## 🔍 Section 4: Pipes — The Heart of Unix Philosophy

The pipe `|` connects stdout of one command to stdin of another.

```bash
command1 | command2
```

```
┌──────────┐    stdout     ┌──────────┐
│ command1 │──────────────►│ command2 │
└──────────┘               └──────────┘
```

### Simple Examples

```bash
# List files, then filter for "hosts"
ls /etc | grep hosts

# Count processes owned by root
ps aux | grep root | wc -l

# See the largest files in /var/log
ls -lS /var/log | head -5

# Show disk usage sorted by size
df -h | sort -k5 -n
```

### The Unix Philosophy in One Sentence

> **"Do one thing and do it well, then chain them together."**

Each command does one job:
- `ls` — lists files
- `grep` — filters lines
- `sort` — sorts lines
- `wc` — counts lines
- `head` — shows first lines

Chained together, they solve complex problems.

### Building a Pipeline Step by Step

```bash
# Problem: Find the 5 largest files in /var/log

# Step 1: List files with sizes
ls -l /var/log
# Result: -rw-r--r-- 1 root root 12345 Jan 15 10:30 syslog

# Step 2: Sort by file size (5th field) numerically
ls -l /var/log | sort -k5 -n

# Step 3: Take the last 5 (largest)
ls -l /var/log | sort -k5 -n | tail -5

# Step 4: Keep only the filename (last field)
ls -l /var/log | sort -k5 -n | tail -5 | awk '{print $NF}'
```

### Even More Powerful Pipelines

```bash
# How many unique users are running processes?
ps aux | awk '{print $1}' | sort | uniq | wc -l

# What are the top 5 commands in your history?
history | awk '{print $2}' | sort | uniq -c | sort -rn | head -5

# Find all listening ports and their programs
ss -tlnp | awk 'NR>1 {print $4, $7}' | sort

# Show disk usage of top-level directories
du -sh /* 2>/dev/null | sort -rh | head -10
```

---



---

[← Previous](04-section-3-redirecting-stdin-the.md) | [↑ Index](index.md) | [Next →](06-common-pipe-patterns-every-sysadmin.md)
