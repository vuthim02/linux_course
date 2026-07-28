## 9. Error Handling

### `set -e` (Exit on Error)

```bash
#!/bin/bash
set -e   # Script exits immediately if any command fails

mkdir /tmp/testdir
cp data.txt /tmp/testdir/
rm data.txt
# If mkdir fails, script stops (won't try cp)
```

### `set -u` (Treat Unset Variables as Error)

```bash
#!/bin/bash
set -u   # Using undefined variable = error
echo "$NAME"   # Error: NAME is unset
```

### `set -o pipefail`

```bash
#!/bin/bash
set -o pipefail
# Pipeline fails if ANY command in the pipeline fails

# Without pipefail: exit code is from last command (false)
false | true    # Exit code = 0

# With pipefail: exit code is from first failed command
set -o pipefail
false | true    # Exit code = 1
```

### Combined: The Safe Script Header

```bash
#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
```

### `trap` for Cleanup

```bash
#!/bin/bash

cleanup() {
    echo "Cleaning up..."
    rm -rf "$TEMP_DIR"
    echo "Done."
}

# Trap EXIT (runs on script exit, even from error)
trap cleanup EXIT

# Trap specific signals
trap 'echo "Interrupted!"; exit 1' SIGINT SIGTERM

# Trap ERR (runs on any command failure)
trap 'echo "Error on line $LINENO"' ERR

# Your script logic
TEMP_DIR=$(mktemp -d)
echo "Working in $TEMP_DIR"
# cleanup runs automatically on exit
```

### Practical Trap Example

```bash
#!/bin/bash
set -euo pipefail

TEMP_FILES=()
CLEANUP_DONE=false

cleanup() {
    $CLEANUP_DONE && return
    CLEANUP_DONE=true
    echo "[CLEANUP] Removing temp files..." >&2
    rm -rf "${TEMP_FILES[@]}"
}

error_handler() {
    local line=$1
    local cmd=$2
    echo "[ERROR] Command failed at line $line: $cmd" >&2
    cleanup
    exit 1
}

trap cleanup EXIT
trap 'error_handler $LINENO "$BASH_COMMAND"' ERR

temp1=$(mktemp /tmp/script-XXXXXX)
TEMP_FILES+=("$temp1")
echo "data" > "$temp1"

echo "Script running..."
```

### Logging Functions

```bash
#!/bin/bash

LOG_FILE="/var/log/myscript.log"

log() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [${level}] ${message}" | tee -a "$LOG_FILE"
}

info()    { log "INFO" "$1"; }
warn()    { log "WARN" "$1"; }
error()   { log "ERROR" "$1" >&2; }
debug()   { log "DEBUG" "$1"; }

info "Starting backup..."
warn "Disk is 85% full"
error "Failed to connect to database"
```





[← Previous](12-8-inputoutput.md) | [↑ Index](index.md) | [Next →](14-10-arrays.md)
