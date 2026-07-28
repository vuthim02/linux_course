## 🔍 Section 2: Process Substitution — `<()` and `>()`

Process substitution lets you use the output of a command as if it were a file.

```bash
# Compare output of two commands
diff <(ls /etc) <(ls /etc/default)

# Count lines matching a pattern from two different sources
cat <(grep -c "error" log1.txt) <(grep -c "error" log2.txt)

# Use command output where only filenames are accepted
wc -l <(find /etc -name "*.conf" 2>/dev/null)
```

### Real Example — Compare Two Directories

```bash
# List files in two directories and diff them
diff <(ls -la /etc) <(ls -la /etc/default)
```





[← Previous](14-section-1-exec-redirecting-streams.md) | [↑ Index](index.md) | [Next →](16-section-3-file-descriptors-more.md)
