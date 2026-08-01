## 📏 Rules of Thumb

### The Script Writing Rules

| Rule | Description | Why |
|------|-------------|-----|
| **Always use set -euo pipefail** | Catch errors early | Prevents silent failures |
| **Always quote variables** | Prevent word splitting | Safety |
| **Always check exit codes** | Know if commands succeed | Reliability |
| **Always log to stderr** | Keep stdout clean | Composability |
| **Always use functions** | Avoid repetition | Maintainability |

### The Shebang Rules

| Situation | Use | Why |
|-----------|-----|-----|
| General scripting | `#!/bin/bash` | Most features |
| POSIX compatibility | `#!/bin/sh` | Maximum portability |
| Unknown system | `#!/usr/bin/env bash` | Finds bash automatically |

### The Error Handling Rules

```bash
# Trap errors:
trap 'echo "Error on line $LINENO" >&2' ERR

# Trap exit:
trap 'cleanup' EXIT

# Cleanup function:
cleanup() {
    rm -f "$TEMP_FILE"
}
```

### The Variable Rules

| Rule | Example | Why |
|------|---------|-----|
| Always quote | `"$variable"` | Prevents word splitting |
| Use ${} syntax | `${variable}` | Cleaner, unambiguous |
| Default values | `${var:-default}` | Prevents unset errors |
| Check existence | `[[ -v var ]]` | Verify before use |

### The Debugging Rules

```bash
# Check syntax without running:
bash -n script.sh

# Run with debug output:
bash -x script.sh

# Add debug to script:
set -x    # Enable debug output
set +x    # Disable debug output

# Use shellcheck (static analysis):
shellcheck script.sh
```

### The "Script Doesn't Work" Checklist

```bash
# 1. Check shebang:
head -1 script.sh

# 2. Check syntax:
bash -n script.sh

# 3. Run with debug:
bash -x script.sh

# 4. Check exit codes:
echo $?    # After each command

# 5. Check variables:
set -u    # Catch unset variables

# 6. Check file permissions:
ls -la script.sh
chmod +x script.sh
```

---

**Why these rules matter:** Following these rules prevents 95% of shell scripting bugs. They're the "seatbelts" of automation.

[← Previous](20-self-test-can-you-answer-these.md) | [↑ Index](index.md)
