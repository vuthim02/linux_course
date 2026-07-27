## 7. Functions

### Defining Functions

```bash
# Style 1: POSIX
myfunc() {
    echo "Hello from function"
}

# Style 2: Bash (function keyword)
function myfunc {
    echo "Hello from function"
}
```

### Function Arguments

```bash
greet() {
    local name="$1"
    local greeting="${2:-Hello}"
    echo "$greeting, $name!"
}

greet "Alice"           # Hello, Alice!
greet "Bob" "Hi"        # Hi, Bob!
```

### Local Variables

```bash
#!/bin/bash

counter=0  # Global

increment() {
    local counter=$1  # Local (shadows global)
    counter=$((counter + 1))
    echo "Inside: $counter"
}

increment 5   # Inside: 6
echo "Outside: $counter"  # Outside: 0
```

### Return Values

```bash
# Exit code (0-255)
is_root() {
    [ "$(id -u)" -eq 0 ]
}

if is_root; then
    echo "Running as root"
fi

# Return string via echo (capture with $())
get_os() {
    echo "$(uname -s)-$(uname -r)"
}
OS=$(get_os)
```

### Sourcing Libraries

```bash
# lib.sh (library file)
log_info() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $1" >&2
}

# main.sh (uses library)
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

log_info "Starting deployment"
```

---



---

[← Previous](10-level-2-intermediary-functions-error.md) | [↑ Index](index.md) | [Next →](12-8-inputoutput.md)
