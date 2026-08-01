## 🔍 Section 1: Error Handling — Writing Robust Scripts

### Defensive Shebang

```bash
#!/bin/bash
set -Eeuo pipefail
# -E: trap ERR in functions/subshells
# -e: exit on any command failure
# -u: treat unset variables as error
# -o pipefail: fail pipeline if any stage fails
```

### The `trap` Command — Catching Signals and Errors

```bash
#!/bin/bash
set -Eeuo pipefail

cleanup() {
  echo "Cleaning up temporary files..."
  rm -rf /tmp/myscript_*
}

error_handler() {
  local line=$1
  local code=$2
  echo "Error on line $line (exit code: $code)" >&2
}

trap cleanup EXIT              # Always runs on exit
trap 'error_handler $LINENO $?' ERR   # Runs on any error
trap 'echo "Interrupted!"; exit 1' INT TERM

# Usage: the script cleans up even if it crashes
```

### Input Validation Patterns

```bash
#!/bin/bash

# Validate argument count
if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <input_file> [output_file]" >&2
  exit 1
fi

# Validate file exists
INPUT="$1"
if [ ! -f "$INPUT" ]; then
  echo "Error: '$INPUT' is not a file" >&2
  exit 1
fi

# Validate numeric input
read -p "Enter a number: " num
if ! [[ "$num" =~ ^[0-9]+$ ]]; then
  echo "Error: Not a number" >&2
  exit 1
fi

# Validate choices
case "${2:-}" in
  fast|full) MODE="$2" ;;
  "")        MODE="fast" ;;
  *)         echo "Usage: $0 [fast|full]" >&2; exit 1 ;;
esac
```

### Checking Command Existence

```bash
require() {
  local cmd="$1"
  if ! command -v "$cmd" &> /dev/null; then
    echo "Error: '$cmd' is required but not installed" >&2
    exit 1
  fi
}

require "jq"
require "curl"
```

### Idempotent Scripting Pattern

```bash
#!/bin/bash
# A script is idempotent if running it N times produces the same result as once.

create_user() {
  local user="$1"
  if id "$user" &> /dev/null; then
    echo "User $user already exists — skipping"
    return 0
  fi
  useradd "$user"
  echo "Created user $user"
}
```

### Logging with Timestamps and Levels

```bash
LOG_FILE="/var/log/myscript.log"

log() {
  local level="$1"
  local message="$2"
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE" >&2
}

log "INFO"  "Script started"
log "ERROR" "Something went wrong"
```



[← Previous](12-level-2-practices.md) | [↑ Index](index.md) | [Next →](14-section-2-professional-script-template.md)
