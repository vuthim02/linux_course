## 🔍 Section 2: Exit Codes — Success or Failure

Every command returns an **exit code** (0 = success, 1-255 = failure).

```bash
# Check the exit code of the last command
$ ls /etc
$ echo $?
# 0 (success)

$ ls /nonexistent
$ echo $?
# 2 (error)

# In a script, use exit codes to signal success/failure
if [ -f "$file" ]; then
    echo "File found"
    exit 0      # Explicit success
else
    echo "File not found" >&2
    exit 1      # Explicit failure
fi
```

### Common Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error |
| 2 | Misuse of shell builtins |
| 126 | Command cannot execute (not executable) |
| 127 | Command not found |
| 128 | Invalid exit argument |
| 130 | Script terminated by Ctrl+C (128 + SIGINT) |
| 137 | Script killed (128 + SIGKILL) |

### Using `set -e` — Exit on Error

```bash
#!/bin/bash
set -e   # Script exits immediately if ANY command fails

# Without set -e:
cp /etc/hosts /backup/    # If this fails, script continues!
rm -rf /important/data     # Disaster!

# With set -e:
set -e
cp /etc/hosts /backup/    # If this fails, script STOPS
```

> 💡 **Always include these at the top of every professional script:**
> ```bash
> set -euo pipefail
> # -e: exit on error
> # -u: error on undefined variables
> # -o pipefail: fail if any command in a pipe fails
> ```
>
> Or the more defensive version:
> ```bash
> set -Eeuo pipefail
> # -E: trap ERR signals in functions/subshells
> ```





[← Previous](07-section-1-loops-doing-things.md) | [↑ Index](index.md) | [Next →](09-section-3-functions-reusable-code.md)
