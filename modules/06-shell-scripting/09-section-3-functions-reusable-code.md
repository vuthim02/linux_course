## 🔍 Section 3: Functions — Reusable Code

```bash
# Define a function
function greet() {
    local name="$1"     # First argument to the function
    echo "Hello, $name!"
}

# Or without the function keyword (POSIX-compatible)
greet() {
    echo "Hello, $1!"
}

# Call it
greet "Alice"
greet "Bob"

# Function with return value
is_root() {
    if [ "$(id -u)" -eq 0 ]; then
        return 0    # True
    else
        return 1    # False
    fi
}

if is_root; then
    echo "Running as root"
else
    echo "Not running as root"
fi
```

### Variable Scope

```bash
global_var="I am global"

myfunc() {
    local local_var="I am local"
    echo "Inside: $local_var"
    echo "Inside: $global_var"
}

myfunc
echo "Outside: $global_var"
echo "Outside: $local_var"  # Empty — local_var is gone
```

### Functions With Arguments

```bash
log_message() {
    local level="$1"
    local message="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message"
}

log_message "INFO" "System started"
log_message "ERROR" "Disk full"
```

---



---

[← Previous](08-section-2-exit-codes-success.md) | [↑ Index](index.md) | [Next →](10-section-4-arrays-multiple-values.md)
