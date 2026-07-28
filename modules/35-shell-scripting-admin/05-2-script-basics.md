## 2. Script Basics

### The Shebang (`#!`)

```bash
#!/bin/bash
```

The shebang tells the kernel which interpreter to use. When you run `./script.sh`, the kernel reads the first two bytes (`#!`), extracts `/bin/bash`, and runs:

```
/bin/bash ./script.sh
```

Other common shebangs:

```bash
#!/bin/sh          # Bourne shell (minimal, POSIX)
#!/bin/bash        # Bash (most features)
#!/bin/dash        # Dash (fast, minimal, Ubuntu /bin/sh)
#!/usr/bin/env bash # Portable (finds bash in PATH)
```

### Execution Methods

```bash
# Method 1: Direct (requires +x permission)
chmod +x script.sh
./script.sh

# Method 2: Pass to interpreter (no +x needed)
bash script.sh

# Method 3: Source into current shell (variables persist!)
source script.sh
. script.sh
```

**Critical difference:**

| Method | New process? | Variables affect caller? |
|---|---|---|
| `./script.sh` | Yes (subshell) | No |
| `bash script.sh` | Yes (subshell) | No |
| `source script.sh` | No (current shell) | Yes |
| `. script.sh` | No (current shell) | Yes |

### Exit Codes

Every command returns an exit code (0 = success, non-0 = failure).

```bash
ls /tmp
echo $?    # Prints 0 (success)

ls /nonexistent
echo $?    # Prints 2 (error)
```

Convention:
- `0` = success
- `1` = general error
- `2` = misuse of shell builtins
- `126` = command not executable
- `127` = command not found
- `128+n` = killed by signal n
- `130` = terminated by Ctrl+C (128 + 2)

```bash
#!/bin/bash
exit 0   # Success
exit 1   # Generic error
exit 127 # Command not found style
```





[← Previous](04-1-why-shell-scripting.md) | [↑ Index](index.md) | [Next →](06-3-variables.md)
