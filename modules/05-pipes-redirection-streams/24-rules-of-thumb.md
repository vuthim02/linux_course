## 📏 Rules of Thumb

### The Redirection Rules

| Rule | Description | Why |
|------|-------------|-----|
| **Think before >** | Overwrites are permanent | Data loss risk |
| **Use >> for logs** | Append is safer | Preserves existing data |
| **Suppress errors** | `2>/dev/null` hides noise | Cleaner output |
| **Log everything** | `command 2>&1 \| tee log.txt` | Debug later |
| **Use tee for logging** | See output AND save it | Best of both worlds |

### The Pipe Rules

| Rule | Description | Why |
|------|-------------|-----|
| **One job per command** | Each command does one thing | Composability |
| **Sort early** | Reduce data flowing through pipe | Performance |
| **Head/tail late** | Don't lose data you might need | Correctness |
| **Use xargs for files** | Handle filenames with spaces | Safety |

### The "No Output" Checklist

```bash
# 1. Is the command producing output?
command    # Check stdout

# 2. Is output going to stderr?
command 2>&1    # Combine stdout+stderr

# 3. Is the command failing silently?
echo $?    # Check exit code

# 4. Is the pipe eating output?
command | cat    # Test without pipe

# 5. Is the terminal filtering?
command | less   # Use pager
```

### The "Too Much Output" Checklist

```bash
# 1. Filter with grep:
command | grep "pattern"

# 2. Limit with head/tail:
command | head -20

# 3. Count instead of list:
command | wc -l

# 4. Paginate:
command | less

# 5. Save and search later:
command > output.txt
grep "pattern" output.txt
```

### The xargs Safety Pattern

```bash
# UNSAFE: filenames with spaces break:
find . -name "*.log" | xargs rm

# SAFE: use null delimiter:
find . -name "*.log" -print0 | xargs -0 rm

# The -print0 and -0 pair:
# -print0: separates files with null byte (\0)
# -0: reads null-delimited input
```

---

**Why these rules matter:** Redirection and pipes are powerful but unforgiving. Following these rules prevents data loss and makes your commands predictable.

[← Previous](22-self-test-can-you-answer-these.md) | [↑ Index](index.md)
