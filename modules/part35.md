# 🐧 Linux System Administrator — Complete Course
## Part 35 of ∞: Shell Scripting for System Administrators

> **Reverse Engineering Approach:** Instead of memorizing syntax, we look at *real admin problems* and reverse-engineer the shell scripting constructs needed to solve them. Every concept here exists because sysadmins needed to automate something tedious.

---

## 🎯 What You Will Achieve

| Level | Outcome |
|-------|---------|
| **Basic** | Write shell scripts with shebangs, variables, conditionals (`if`/`case`), and loops (`for`/`while`); understand exit codes, quoting, and execution methods |
| **Intermediary** | Create reusable functions and libraries; handle errors with `set -euo pipefail` and `trap`; parse CLI args with `getopts`; use arrays, here-docs, and process I/O |
| **Advanced** | Implement security-conscious scripts (input validation, `mktemp`, PATH safety); use associative arrays; understand fork/exec model, expansion order, subshells, and debugging techniques |

---

## Table of Contents

1. Why Shell Scripting?
2. Script Basics
3. Variables
4. String Operations
5. Conditionals
6. Loops
7. Functions
8. Input/Output
9. Error Handling
10. Arrays
11. Parsing Command-Line Args
12. Security in Scripts
13. Real Admin Script Examples
14. 15 Hands-On Practices
15. Deep Understanding
16. Command Reference
17. Self-Test
18. What's Coming in Part 36

---

## ⭐ Level 1: Basic — Writing Your First Scripts

![Bash logo — GNU Bash the Bourne Again SHell](https://upload.wikimedia.org/wikipedia/commons/thumb/8/82/GNU_bash_logo.svg/320px-GNU_bash_logo.svg.png)

> *"Shell scripting is the glue of Linux administration. When you find yourself typing the same five commands every day, that's a script waiting to happen. A good script is one you forget you wrote because it just works for years."*

---

## 1. Why Shell Scripting?

Shell scripting is the **glue** of Linux administration.

### What admins automate with shell scripts:

| Task | Why Script It |
|---|---|
| **Backups** | `tar` + `rsync` + rotation logic = never lose data |
| **Cron jobs** | System maintenance at 3 AM while you sleep |
| **Deployment** | Push code to 50 servers in one command |
| **Monitoring** | Check disk, CPU, memory, services every 5 minutes |
| **User management** | Create 200 accounts from a CSV file |
| **Log rotation** | Compress, archive, delete old logs automatically |
| **Health checks** | Ping services, restart if dead, email alerts |

### The sysadmin mindset:

```
Manual task + Repetition = Script
Script + Edge cases = Robust tool
Robust tool + Documentation = Team asset
```

---

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

---

## 3. Variables

### Basic Assignment

```bash
# NO spaces around =
NAME="Alice"
AGE=30
VERSION=$(uname -r)   # Command substitution
DATE=`date +%Y%m%d`   # Old-style (avoid, use $())
```

### Variable Expansion

```bash
echo $NAME
echo ${NAME}          # Braces for clarity
echo "Hello, ${NAME}" # Always quote!

# Default values
echo ${NAME:-"default"}  # Use default if unset/null
echo ${NAME:="default"}  # Assign default if unset/null
echo ${NAME:?"error msg"} # Error if unset/null
```

### Positional Parameters

```bash
#!/bin/bash
# Save as: args.sh

echo "Script name: $0"
echo "First arg: $1"
echo "Second arg: $2"
echo "All args: $@"
echo "All args (single string): $*"
echo "Number of args: $#"
```

### Special Variables

| Variable | Meaning |
|---|---|
| `$0` | Script name |
| `$1-$9` | Positional arguments |
| `$#` | Number of arguments |
| `$@` | All arguments (each quoted) |
| `$*` | All arguments (single string) |
| `$?` | Exit code of last command |
| `$$` | PID of current script |
| `$!` | PID of last background process |
| `$LINENO` | Current line number in script |

---

## 4. String Operations

### Length and Substring

```bash
str="Hello, Linux!"
echo ${#str}   # 13

str="sysadmin"
echo ${str:0:3}   # sys (offset 0, length 3)
echo ${str:3}     # admin (offset 3 to end)
echo ${str: -3}   # min (last 3 chars, space needed)
```

### Pattern Replacement

```bash
file="backup-2025-01-15.tar.gz"
echo ${file/tar.gz/zip}      # backup-2025-01-15.zip
echo ${file//o/O}            # backup-2025-01-15.tar.gz (replace all)

text="foo foo foo"
echo ${text/foo/bar}         # bar foo foo
echo ${text//foo/bar}        # bar bar bar

echo ${file/#backup/snapshot}  # Replace prefix
echo ${file/%.tar.gz/.zip}     # Replace suffix
```

### Case Modification

```bash
name="linux"
echo ${name^^}   # LINUX (uppercase)
echo ${name^}    # Linux (capitalize first)

OS="LINUX"
echo ${OS,,}     # linux (lowercase)
```

### Quoting Rules

```bash
# Single quotes: literal, no expansion
echo 'The $HOME variable is $HOME'

# Double quotes: expansion happens
echo "The $HOME variable is $HOME"

# No quotes: word splitting + glob expansion
echo $PATH                           # Splits on IFS, glob expands

# Best practice: ALWAYS double-quote variable expansions
file="my file.txt"
cat $file       # Fails: tries cat my file.txt
cat "$file"     # Works
```

---

## 5. Conditionals

### if/then/elif/else/fi

```bash
#!/bin/bash

if [ "$1" = "start" ]; then
    echo "Starting service..."
elif [ "$1" = "stop" ]; then
    echo "Stopping service..."
elif [ "$1" = "restart" ]; then
    echo "Restarting service..."
else
    echo "Usage: $0 {start|stop|restart}"
    exit 1
fi
```

### The `test` Command (`[ ]`)

```bash
# These are identical:
test "$a" = "$b"
[ "$a" = "$b" ]
```

### String Tests

```bash
[ "$str" = "hello" ]    # Equal (POSIX)
[ "$str" != "hello" ]   # Not equal
[ -z "$str" ]           # Length is zero (empty)
[ -n "$str" ]           # Length is non-zero
```

### Numeric Tests

```bash
[ "$a" -eq "$b" ]   # Equal
[ "$a" -ne "$b" ]   # Not equal
[ "$a" -lt "$b" ]   # Less than
[ "$a" -le "$b" ]   # Less than or equal
[ "$a" -gt "$b" ]   # Greater than
[ "$a" -ge "$b" ]   # Greater than or equal
```

### File Tests

```bash
[ -f "$file" ]    # Is a regular file
[ -d "$dir" ]     # Is a directory
[ -e "$path" ]    # Exists
[ -s "$file" ]    # Not empty (size > 0)
[ -r "$file" ]    # Readable
[ -w "$file" ]    # Writable
[ -x "$file" ]    # Executable
[ -L "$file" ]    # Is a symlink
```

### `[[ ]]` vs `[ ]`

| Feature | `[ ]` (POSIX) | `[[ ]]` (Bash) |
|---|---|---|
| Word splitting | Yes | No |
| Pathname expansion | Yes | No |
| Regex matching | No | `=~` operator |
| Pattern matching | No | `==` with globs |
| Logical operators | `-a`, `-o` | `&&`, `\|\|` |

```bash
# [[ ]] is safer and more powerful
[[ "$str" == "hello" ]]           # No quoting needed
[[ "$str" == h* ]]                # Pattern matching (glob)
[[ "$str" =~ ^[0-9]+$ ]]         # Regex matching
[[ -f "$file" && -r "$file" ]]   # AND with &&
```

### Case Statement

```bash
case "$1" in
    start|begin)
        echo "Starting..."
        ;;
    stop|end)
        echo "Stopping..."
        ;;
    restart)
        echo "Restarting..."
        ;;
    *)
        echo "Unknown option: $1"
        exit 1
        ;;
esac
```

---

## 6. Loops

### `for` Loop

```bash
for i in 1 2 3 4 5; do
    echo "Number: $i"
done

# Brace expansion
for i in {1..10}; do
    echo "$i"
done

# With step
for i in {0..20..2}; do
    echo "Even: $i"
done

# C-style
for ((i=0; i<10; i++)); do
    echo "i = $i"
done
```

### Iterating Over Files

```bash
for file in *.txt; do
    echo "Processing: $file"
    wc -l "$file"
done
```

### `while` Loop

```bash
# Read file line by line
while IFS= read -r line; do
    echo "Line: $line"
done < "/var/log/syslog"

# Infinite loop with break
count=0
while true; do
    echo "Iteration $count"
    ((count++))
    [ "$count" -ge 5 ] && break
done
```

### `until` Loop

```bash
until ping -c1 google.com &>/dev/null; do
    echo "Waiting for network..."
    sleep 5
done
echo "Network is up!"
```

### `break` and `continue`

```bash
for i in {1..10}; do
    [ "$i" -eq 5 ] && continue   # Skip 5
    [ "$i" -eq 8 ] && break      # Stop at 8
    echo "$i"
done
# Prints: 1 2 3 4 6 7
```

---

## ⭐ Level 2: Intermediary — Functions, Error Handling, and Robust Scripts

![Automation diagram showing script-driven administration workflow](https://upload.wikimedia.org/wikipedia/commons/6/6a/Bash_screenshot.png)

> *"A script that crashes on unexpected input is worse than no script at all — it gives you false confidence. Real sysadmin scripts have error handlers, input validation, logging, and cleanup routines. `set -euo pipefail` is not optional — it's the minimum bar for professional-grade automation."*

---

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

## 8. Input/Output

### `read` — Getting User Input

```bash
read -p "Enter username: " username
read -s -p "Enter password: " password   # Silent
read -t 5 -p "Quick! (5 sec): " answer   # With timeout
read -a numbers -p "Enter numbers: "     # Read into array
read -d ':' field1 field2 <<< "user:pass"
```

### `echo` vs `printf`

```bash
echo "Hello world"
echo -n "No newline"

# printf (formatted, more portable)
printf "Hello %s, you are %d years old\n" "Alice" 30
printf "%-15s %5s\n" "Name" "Age"
printf "%-15s %5d\n" "Alice" 30

# Format specifiers
printf "%s\n" "string"
printf "%d\n" 123      # Integer
printf "%f\n" 3.14     # Float
printf "%x\n" 255      # Hexadecimal (ff)
```

### Here-Documents (`<<EOF`)

```bash
# Multi-line input
cat <<EOF
This is a multi-line
message that preserves
formatting.
EOF

# No expansion (quote delimiter)
cat <<'EOF'
The $HOME variable is $HOME
No expansion here!
EOF

# Write to file
cat <<EOF > /etc/myapp/config.conf
server.port = 8080
server.host = 0.0.0.0
EOF

# Append to file
cat <<EOF >> /etc/myapp/config.conf
log.level = DEBUG
EOF
```

### Here-Strings (`<<<`)

```bash
grep "error" <<< "no errors here"
read first last <<< "John Doe"
bc <<< "scale=2; 10/3"   # 3.33
tr '[:lower:]' '[:upper:]' <<< "linux"   # LINUX
```

### File Descriptors

```bash
# Standard streams
0 = stdin
1 = stdout
2 = stderr

# Redirect stdout to file
ls > /tmp/output.txt

# Redirect stderr to file
ls /nonexistent 2> /tmp/error.txt

# Both to same file
ls &> /tmp/all.txt         # Bash 4+
ls > /tmp/all.txt 2>&1     # POSIX

# Discard output
ls > /dev/null 2>&1

# Custom file descriptors
exec 3> /tmp/debug.log     # Open FD 3 for writing
echo "debug message" >&3
exec 3>&-                 # Close FD 3
```

---

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

---

## 10. Arrays

### Indexed Arrays

```bash
# Declaration
fruits=("apple" "banana" "cherry")
numbers=(1 2 3 4 5)

# Access
echo "${fruits[0]}"    # apple
echo "${fruits[-1]}"   # cherry (last element)

# All elements
echo "${fruits[@]}"    # apple banana cherry

# Length
echo "${#fruits[@]}"   # 3
echo "${#fruits[0]}"   # 5 (length of "apple")

# Append
fruits+=("date")

# Slice
echo "${fruits[@]:1:2}"    # banana cherry

# Iterate
for fruit in "${fruits[@]}"; do
    echo "$fruit"
done

# Remove element
unset "fruits[1]"      # Removes banana
```

---

## 11. Parsing Command-Line Args

### `getopts` — Short Options

```bash
#!/bin/bash

usage() {
    echo "Usage: $0 [-v] [-o output_file] [-n count] name"
    exit 1
}

verbose=false
output_file=""
count=1

while getopts ":vo:n:" opt; do
    case $opt in
        v)
            verbose=true
            ;;
        o)
            output_file="$OPTARG"
            ;;
        n)
            count="$OPTARG"
            [[ "$count" =~ ^[0-9]+$ ]] || { echo "Count must be a number"; exit 1; }
            ;;
        \?)
            echo "Invalid option: -$OPTARG"
            usage
            ;;
        :)
            echo "Option -$OPTARG requires an argument"
            usage
            ;;
    esac
done

shift $((OPTIND - 1))

if [ $# -lt 1 ]; then
    echo "Error: name argument is required"
    usage
fi

name="$1"
echo "Count: $count, Output: ${output_file:-stdout}, Name: $name"
```

### Manual `shift` Parsing (POSIX)

```bash
#!/bin/bash

verbose=false
output_file=""
count=1

while [ $# -gt 0 ]; do
    case "$1" in
        --verbose|-v)
            verbose=true
            shift
            ;;
        --output|-o)
            output_file="$2"
            shift 2
            ;;
        --count|-n)
            count="$2"
            shift 2
            ;;
        --help|-h)
            usage
            ;;
        --*|-*)
            echo "Unknown option: $1"
            usage
            ;;
        *)
            break
            ;;
    esac
done

name="$1"
echo "Name: $name, Verbose: $verbose, Output: ${output_file:-stdout}, Count: $count"
```

---

## 13. Real Admin Script Examples

### Example 1: Backup Script

```bash
#!/bin/bash
set -euo pipefail

# backup.sh — Full backup with rotation

SOURCE_DIR="${1:?Error: Source directory required}"
BACKUP_DIR="${2:-/var/backups}"
RETENTION_DAYS=30
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
BACKUP_NAME="backup_$(basename "$SOURCE_DIR")_${TIMESTAMP}.tar.gz"
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_NAME}"
LOG_FILE="${BACKUP_DIR}/backup.log"

log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$msg" | tee -a "$LOG_FILE"
}

cleanup() {
    log "Cleaning up..."
}

error_handler() {
    log "ERROR on line $1: $2"
    cleanup
    exit 1
}

trap cleanup EXIT
trap 'error_handler $LINENO "$BASH_COMMAND"' ERR

[ -d "$SOURCE_DIR" ] || { log "Source $SOURCE_DIR not a directory"; exit 1; }
[ -d "$BACKUP_DIR" ] || mkdir -p "$BACKUP_DIR"

log "Starting backup of $SOURCE_DIR"

tar -czf "$BACKUP_PATH" -C "$(dirname "$SOURCE_DIR")" "$(basename "$SOURCE_DIR")"
log "Created: $BACKUP_PATH ($(du -h "$BACKUP_PATH" | cut -f1))"

log "Removing backups older than ${RETENTION_DAYS} days"
find "$BACKUP_DIR" -name "backup_$(basename "$SOURCE_DIR")_*.tar.gz" \
    -type f -mtime "+${RETENTION_DAYS}" -delete

# Keep only last 10 backups
count=$(ls -1 "${BACKUP_DIR}/backup_$(basename "$SOURCE_DIR")_"*.tar.gz 2>/dev/null | wc -l)
if [ "$count" -gt 10 ]; then
    ls -1t "${BACKUP_DIR}/backup_$(basename "$SOURCE_DIR")_"*.tar.gz | \
        tail -n $((count - 10)) | xargs rm -f
    log "Removed $((count - 10)) old backups (retaining 10)"
fi

log "Backup completed successfully"
```

### Example 2: Log Rotator

```bash
#!/bin/bash
set -euo pipefail

CONFIG_FILE="${1:-/etc/myapp/logrotate.conf}"
ROTATE_DIR="/var/log/myapp/archive"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

rotate_log() {
    local logfile="$1"
    local max_size="$2"
    local keep_count="$3"

    [ -f "$logfile" ] || { log "SKIP: $logfile not found"; return 0; }

    local size
    size=$(stat -f%z "$logfile" 2>/dev/null || stat -c%s "$logfile" 2>/dev/null)

    if [ "$size" -lt "$max_size" ]; then
        log "OK: $logfile ($(numfmt --to=iec $size)) under limit"
        return 0
    fi

    log "ROTATING: $logfile ($(numfmt --to=iec $size)) exceeds limit"

    local timestamp
    timestamp=$(date '+%Y%m%d_%H%M%S')
    local archived="${ROTATE_DIR}/$(basename "$logfile").${timestamp}.gz"

    mkdir -p "$ROTATE_DIR"

    gzip -c "$logfile" > "$archived"
    : > "$logfile"    # Truncate original

    log "ARCHIVED: $archived ($(du -h "$archived" | cut -f1))"

    local count
    count=$(ls -1t "${ROTATE_DIR}/$(basename "$logfile")."*.gz 2>/dev/null | wc -l)
    if [ "$count" -gt "$keep_count" ]; then
        ls -1t "${ROTATE_DIR}/$(basename "$logfile")."*.gz 2>/dev/null | \
            tail -n $((count - keep_count)) | xargs rm -f
        log "CLEANUP: Removed $((count - keep_count)) old archives"
    fi
}

while IFS=' ' read -r logfile max_size keep_count; do
    [[ -z "$logfile" || "$logfile" == \#* ]] && continue
    rotate_log "$logfile" "$max_size" "$keep_count"
done < "$CONFIG_FILE"

log "Log rotation complete"
```

### Example 3: Health Check Script

```bash
#!/bin/bash
set -euo pipefail

ALERT_EMAIL="admin@example.com"
ALERT_DISK=90
ALERT_CPU=80
ALERT_MEM=90
HOSTNAME=$(hostname)
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

report_file=$(mktemp /tmp/health-XXXXXX)
trap 'rm -f "$report_file"' EXIT

alert() {
    local severity="$1"
    local message="$2"
    echo "[${TIMESTAMP}] [${severity}] ${message}" >> "$report_file"

    if [ "$severity" = "CRITICAL" ]; then
        echo "CRITICAL: $message" | \
            mail -s "[ALERT] ${HOSTNAME}: ${message}" "$ALERT_EMAIL"
    fi
}

check_disk() {
    df -h --exclude-type=tmpfs --exclude-type=devtmpfs | tail -n +2 | while read -r line; do
        local usage mount
        usage=$(echo "$line" | awk '{print $5}' | tr -d '%')
        mount=$(echo "$line" | awk '{print $6}')

        if [ "$usage" -ge "$ALERT_DISK" ]; then
            alert "CRITICAL" "Disk ${usage}% full on ${mount}"
        elif [ "$usage" -ge $((ALERT_DISK - 10)) ]; then
            alert "WARNING" "Disk ${usage}% full on ${mount}"
        fi
    done
}

check_cpu() {
    local load cores pct
    load=$(awk '{print $1}' /proc/loadavg)
    cores=$(nproc)
    pct=$(echo "$load $cores" | awk '{printf "%d", ($1/$2)*100}')

    if [ "$pct" -ge "$ALERT_CPU" ]; then
        alert "WARNING" "CPU load at ${pct}% (load: ${load}, cores: ${cores})"
    fi
}

check_memory() {
    local total used pct
    total=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
    used=$(awk '/^Active:/ {print $2}' /proc/meminfo)
    pct=$((used * 100 / total))

    if [ "$pct" -ge "$ALERT_MEM" ]; then
        alert "CRITICAL" "Memory at ${pct}%"
    elif [ "$pct" -ge $((ALERT_MEM - 10)) ]; then
        alert "WARNING" "Memory at ${pct}%"
    fi
}

check_services() {
    local services=("sshd" "cron" "rsyslog" "nginx")
    for svc in "${services[@]}"; do
        if systemctl is-active --quiet "$svc" 2>/dev/null; then
            echo "OK: $svc is running" >> "$report_file"
        else
            alert "CRITICAL" "Service $svc is NOT running"
            systemctl try-restart "$svc" 2>/dev/null && \
                alert "INFO" "Attempted restart of $svc"
        fi
    done
}

# Run all checks
echo "Health Check Report — ${HOSTNAME} — ${TIMESTAMP}" > "$report_file"
check_disk
check_cpu
check_memory
check_services

cat "$report_file"
```

### Example 4: User Creation Script

```bash
#!/bin/bash
set -euo pipefail

CSV_FILE="${1:?Usage: $0 <users.csv> [dry-run]}"
DRY_RUN="${2:-false}"
LOG_FILE="/var/log/user-creation.log"
DEFAULT_SHELL="/bin/bash"
PASSWORD_LENGTH=16

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

error_handler() {
    log "ERROR on line $1: $2"
    exit 1
}

trap 'error_handler $LINENO "$BASH_COMMAND"' ERR

[ -f "$CSV_FILE" ] || { log "CSV file $CSV_FILE not found"; exit 1; }

generate_password() {
    < /dev/urandom tr -dc 'A-Za-z0-9!@#$%^&*()_+' | head -c "$PASSWORD_LENGTH"
}

process_user() {
    local username="$1"
    local group="$2"
    local full_name="$3"
    local shell="${4:-$DEFAULT_SHELL}"

    [[ "$username" =~ ^[a-z_][a-z0-9_-]*$ ]] || {
        log "ERROR: Invalid username '$username'"
        return 1
    }

    if id "$username" &>/dev/null; then
        log "SKIP: User '$username' already exists"
        return 0
    fi

    if ! grep -q "^${group}:" /etc/group; then
        log "Creating group: $group"
        [ "$DRY_RUN" = false ] && groupadd "$group"
    fi

    local password
    password=$(generate_password)

    if [ "$DRY_RUN" = true ]; then
        log "DRY-RUN: Would create user: $username"
    else
        useradd -m -g "$group" -c "$full_name" -s "$shell" "$username"
        echo "$username:$password" | chpasswd
        chage -d 0 "$username"
        log "CREATED: $username (group: $group) — password: $password"
    fi
}

while IFS=',' read -r -u3 username group full_name shell; do
    username=$(echo "$username" | xargs)
    [[ -z "$username" || "$username" == \#* ]] && continue
    group=$(echo "$group" | xargs)
    full_name=$(echo "$full_name" | xargs)
    shell=$(echo "$shell" | xargs)
    shell="${shell:-$DEFAULT_SHELL}"
    process_user "$username" "$group" "$full_name" "$shell"
done 3< "$CSV_FILE"

log "User creation complete"
```

---

## ⭐ Level 3: Advanced — Security, Internals, and Professional-Grade Scripting

![Shell expansion order diagram showing the 8 phases of bash parsing](https://upload.wikimedia.org/wikipedia/commons/7/72/Bash_expansion_order.svg)

> *"The difference between a script that works and a script that's secure is a single unquoted variable. The difference between a script that's maintainable and one that isn't is understanding how the shell actually works — the expansion order, the fork/exec model, and the subshell boundaries."*

---

## 12. Security in Scripts

### Quoting to Prevent Injection

```bash
# DANGEROUS: shell injection
filename="$1"
rm -rf $filename
# If filename = "/tmp/foo ; rm -rf /"
# This becomes: rm -rf /tmp/foo ; rm -rf /

# SAFE: always quote
rm -rf "$filename"

# DANGEROUS: command injection
user_input="; rm -rf /"
eval "echo $user_input"   # NEVER use eval with user input

# SAFE: use printf %q (escape for shell)
printf '%q' "$user_input"
```

### Never Use `eval`

```bash
# BAD
eval "echo $@"

# If you must use dynamic variable names (bash 4+), use nameref
var_name="myvar"
declare -n ref="$var_name"
ref="value"
echo "$myvar"   # value
```

### Safe Temporary Files

```bash
# DANGEROUS: predictable temp file
echo "data" > /tmp/tmpdata.txt   # Race condition!

# SAFE: mktemp
tempfile=$(mktemp /tmp/myapp-XXXXXX)
echo "data" > "$tempfile"
rm -f "$tempfile"

# Safe temp directory
tempdir=$(mktemp -d /tmp/myapp-XXXXXX)
trap 'rm -rf "$tempdir"' EXIT
```

### Running as Non-Root

```bash
#!/bin/bash

if [ "$(id -u)" -eq 0 ]; then
    echo "This script should not be run as root!" >&2
    exit 1
fi
```

### PATH Safety

```bash
#!/bin/bash
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
# No . or relative dirs in PATH
```

### Input Validation

```bash
validate_ip() {
    local ip="$1"
    [[ "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] || return 1
    for octet in ${ip//./ }; do
        [ "$octet" -le 255 ] || return 1
    done
    return 0
}

validate_hostname() {
    local host="$1"
    [[ "$host" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?)*$ ]]
}
```

### Secure Password Handling

```bash
# NEVER hardcode passwords!
# Use environment variables (set externally)
DB_PASS="${DB_PASS:?DB_PASS not set}"

# Or prompt securely:
read -s -p "Database password: " DB_PASS
echo

# Or read from restricted file:
DB_PASS=$(cat /etc/myapp/db.pass 2>/dev/null)

# Mask passwords in logs
log_command() {
    local cmd="$1"
    local masked
    masked=$(echo "$cmd" | sed 's/\(passwor[dt]=\)[^ ]*/\1***/gi')
    echo "$masked"
}
```

### Avoiding Command Injection in `find`

```bash
# DANGEROUS: -exec with sh -c
find /tmp -name "*.txt" -exec sh -c 'echo "File: $1"' _ {} \;

# SAFE: use -exec with arguments directly
find /tmp -name "*.txt" -exec echo "File:" {} \;

# SAFER: use -print0 with while read
find /tmp -name "*.txt" -print0 | while IFS= read -r -d '' file; do
    echo "File: $file"
done
```

---

## 15. Deep Understanding

### How Bash Executes Scripts

Bash processes a script in **phases**:

```
1. Tokenization: Split input into tokens (words, operators)
2. Parsing: Build AST from tokens (grammar analysis)
3. Expansion: Process ${}, $(), ~, globs, word splitting
4. Quote removal: Remove quote characters
5. Execution: Run the resulting command
```

**Expansion order** (critical for understanding quoting):

```
1. Brace expansion          {a,b,c}
2. Tilde expansion          ~/dir
3. Parameter expansion      $VAR, ${VAR}
4. Command substitution     $(cmd)
5. Arithmetic expansion     $((expr))
6. Word splitting           (splits on IFS)
7. Pathname expansion       *.txt (globbing)
8. Quote removal
```

### Fork/Exec Model

```bash
# When you run any command (including a script):
bash script.sh
```

1. Bash calls `fork()` — creates a copy of the current process (child)
2. Child process calls `execve("/bin/bash", ["bash", "script.sh"], envp)` — replaces child's memory with new program
3. Parent (`wait()`): suspends until child exits
4. Child runs the script, calls `exit()` when done
5. Parent resumes

**Key insight**: `fork()` duplicates everything — file descriptors, environment, variables (but changes in child don't affect parent).

### Subshells vs Current Shell

```bash
# Subshell (runs in child process)
(cd /tmp && ls)   # Parent stays in original directory

# Current shell
cd /tmp && ls     # Parent changes directory too

# More subshell examples:
command1 | command2     # Pipe creates subshells
$(command)              # Command substitution = subshell
{ command; }            # Current shell (no subshell)
```

### Source vs Execute

```bash
# EXECUTE (./script.sh):
# 1. fork() new process
# 2. Kernel reads #!/bin/bash
# 3. execve("/bin/bash", ["./script.sh"])
# 4. Child runs script, child exits
# 5. Parent unaffected

# SOURCE (source script.sh or . script.sh):
# 1. NO fork()
# 2. Bash reads file line by line in CURRENT shell
# 3. All changes (variables, functions, cd) affect current shell
# 4. No exit — just returns
```

### How the Shebang Kernel Handler Works

When you run `./script.sh`:

1. Kernel opens the file, reads first 2 bytes
2. Detects `#!` (0x23 0x21)
3. Reads rest of first line: `/bin/bash`
4. Kernel effectively runs: `/bin/bash ./script.sh`
5. If the interpreter itself has a shebang (e.g., `/usr/bin/env`), kernel follows the chain

**Limits:**
- Maximum shebang length: typically 127-256 bytes (varies by system)
- Only ONE argument can follow the interpreter path
- The shebang path must be absolute (no PATH lookup)

```bash
# What kernel does:
./script.py    # Kernel reads #!/usr/bin/python3
               # Kernel runs: /usr/bin/python3 ./script.py
```

**Why `#!/usr/bin/env bash` is portable:**

```bash
#!/usr/bin/env bash
# Kernel executes: /usr/bin/env bash ./script.sh
# env searches PATH for bash, finds wherever it lives
```

### Associative Arrays (`declare -A`)

```bash
#!/bin/bash

declare -A config
config["host"]="localhost"
config["port"]=5432
config["user"]="admin"

echo "${config[host]}"     # localhost
echo "${!config[@]}"       # host port user

for key in "${!config[@]}"; do
    echo "$key = ${config[$key]}"
done

# Practical: server status map
declare -A servers
servers["web01"]="192.168.1.10"
servers["db01"]="192.168.1.20"

for name in "${!servers[@]}"; do
    ip="${servers[$name]}"
    ping -c1 "$ip" &>/dev/null && echo "$name ($ip): UP" || echo "$name ($ip): DOWN"
done
```

### Removing Elements from Arrays

```bash
arr=(a b c d e)
unset 'arr[2]'                # arr = (a b d e)
arr=("${arr[@]}")             # Re-index

# Remove by value
arr=(a b c d e b f)
remove_value="b"
for i in "${!arr[@]}"; do
    if [ "${arr[$i]}" = "$remove_value" ]; then
        unset 'arr[i]'
    fi
done
arr=("${arr[@]}")
```

---

## 16. Command Reference

### Level 1: Basic Bash Builtins

| Command | Description |
|---|---|
| `.` | Source a file |
| `echo` | Output text |
| `exit` | Exit shell |
| `export` | Set environment variable |
| `for` | Loop |
| `if` | Conditional |
| `kill` | Send signal |
| `pwd` | Print working directory |
| `read` | Read from stdin |
| `return` | Return from function |
| `shift` | Shift positional params |
| `source` | Source file |
| `test` / `[` | Test condition |
| `while` | Loop while condition |
| `case` | Conditional branch |

### Level 1: External Scripting Tools

| Command | Description |
|---|---|
| `grep` | Search patterns |
| `cut` | Extract columns |
| `sort` | Sort lines |
| `uniq` | Unique lines |
| `wc` | Word/line/char count |
| `date` | Date/time formatting |
| `bc` | Calculator |

### Level 2: Intermediary Bash Builtins

| Command | Description |
|---|---|
| `function` | Define function |
| `getopts` | Parse options |
| `local` | Local variable |
| `printf` | Formatted print |
| `trap` | Set signal handler |
| `mapfile` | Read lines into array |
| `disown` | Remove job from table |
| `wait` | Wait for background job |
| `select` | Select from menu |
| `set` | Set shell options |

### Level 2: Intermediary External Tools

| Command | Description |
|---|---|
| `awk` | Pattern scanning/processing |
| `sed` | Stream editor |
| `tr` | Translate characters |
| `tee` | Split output (file + stdout) |
| `xargs` | Build and exec command lines |
| `find` | Find files |
| `expr` | Evaluate expression |

### Level 3: Advanced Bash Builtins

| Command | Description |
|---|---|
| `declare` | Declare variable/type |
| `eval` | Evaluate string as command |
| `exec` | Replace shell with command |
| `shopt` | Shell options |
| `typeset` | Declare variable |

### Level 3: Advanced External Tools

| Command | Description |
|---|---|
| `jq` | JSON processor |
| `curl` | HTTP client |
| `rsync` | Sync files |
| `ssh` | Remote shell |

### Script Debugging

```bash
# Debug modes
bash -n script.sh       # Syntax check only (no execution)
bash -x script.sh       # Trace execution (print commands)
bash -v script.sh       # Verbose (print input lines)

# In-script debugging
set -x                  # Enable trace
set +x                  # Disable trace

# PS4 for custom trace prompt
export PS4='+ ${BASH_SOURCE}:${LINENO}: ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
```

---

## 14. 15 Hands-On Practices

### Level 1 Practices: Basic Scripting

#### Practice 1: System Info Script

Write a script that displays hostname, OS version, kernel, uptime, CPU load, memory usage, disk usage:

```bash
#!/bin/bash
# system_info.sh

echo "=== System Information ==="
echo "Hostname: $(hostname)"
echo "OS: $(lsb_release -ds 2>/dev/null || cat /etc/os-release 2>/dev/null | head -1)"
echo "Kernel: $(uname -r)"
echo "Uptime: $(uptime -p)"
echo "CPU Load: $(uptime | awk -F'load average:' '{print $2}')"
echo "Memory: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
```

#### Practice 2: Log Analyzer

```bash
#!/bin/bash
# log_analyzer.sh — Analyze access logs

LOG_FILE="${1:-/var/log/nginx/access.log}"

[ -f "$LOG_FILE" ] || { echo "File not found: $LOG_FILE"; exit 1; }

echo "=== Log Analysis: $LOG_FILE ==="
echo
echo "Top 10 IPs:"
awk '{print $1}' "$LOG_FILE" | sort | uniq -c | sort -rn | head -10
echo
echo "Top 10 URLs:"
awk '{print $7}' "$LOG_FILE" | sort | uniq -c | sort -rn | head -10
echo
echo "HTTP Status Codes:"
awk '{print $9}' "$LOG_FILE" | sort | uniq -c | sort -rn
```

### Level 2 Practices: Intermediary Scripting

#### Practice 3: Backup Script with Rotation

Extend the backup example:
- Accept multiple source directories
- Compress with `pigz` (parallel gzip) if available
- Encrypt backups with GPG
- Email success/failure report
- Verify backup integrity after creation

#### Practice 4: User Creation with Error Handling

Build on the user creation example:
- Accept JSON input instead of CSV
- Send welcome email to new users
- Generate SSH keys for each user
- Create home directory skeleton structure
- Log all actions to syslog

#### Practice 5: Monitoring Dashboard

Create a real-time terminal dashboard:
- Use `watch` or a `while` loop with `clear`
- Display: uptime, CPU, memory, disk, network, top processes
- Color-code warnings (green/yellow/red)
- Refresh every 2 seconds

#### Practice 6: Service Restart Wrapper

```bash
#!/bin/bash
# safe_restart.sh — Safe service restart with rollback

SERVICE="$1"
MAX_RETRIES=3
HEALTH_CHECK_URL="http://localhost:8080/health"

restart_service() {
    echo "Restarting $SERVICE..."
    systemctl stop "$SERVICE"
    sleep 2
    systemctl start "$SERVICE"
}

check_health() {
    for i in $(seq 1 10); do
        if curl -sf "$HEALTH_CHECK_URL" &>/dev/null; then
            echo "Service is healthy"
            return 0
        fi
        sleep 2
    done
    return 1
}

for attempt in $(seq 1 "$MAX_RETRIES"); do
    restart_service
    if check_health; then
        echo "Restart successful"
        exit 0
    fi
done

echo "All attempts failed — rolling back"
systemctl start "$SERVICE" || true
exit 1
```

#### Practice 7: Disk Space Alert

```bash
#!/bin/bash
# disk_alert.sh — Disk space monitoring with alerting

THRESHOLD=80
ALERT_EMAIL="admin@example.com"

df -h --exclude-type=tmpfs --exclude-type=devtmpfs | tail -n +2 | while read line; do
    pct=$(echo "$line" | awk '{print $5}' | tr -d '%')
    mount=$(echo "$line" | awk '{print $6}')
    if [ "$pct" -ge "$THRESHOLD" ]; then
        echo "WARNING: $mount at ${pct}%"
    fi
done
```

#### Practice 8: Permission Audit

```bash
#!/bin/bash
# permission_audit.sh — Find security issues

SCAN_DIR="${1:-/home}"
REPORT_FILE="/tmp/perm_audit_$(date +%Y%m%d).txt"

echo "Permission Audit — $(date)" > "$REPORT_FILE"

# World-writable files
find "$SCAN_DIR" -type f -perm -o+w -ls 2>/dev/null >> "$REPORT_FILE"

# SUID/SGID files
find "$SCAN_DIR" -type f \( -perm -4000 -o -perm -2000 \) -ls 2>/dev/null >> "$REPORT_FILE"

# Files with no owner
find "$SCAN_DIR" -nouser -o -nogroup -ls 2>/dev/null >> "$REPORT_FILE"

echo "Report saved to $REPORT_FILE"
```

#### Practice 9: Network Connectivity Checker

```bash
#!/bin/bash
# netcheck.sh — Network connectivity diagnostics

HOSTS=("google.com" "github.com" "8.8.8.8")

for host in "${HOSTS[@]}"; do
    if ping -c2 -W2 "$host" &>/dev/null; then
        echo "OK: $host ($(dig +short "$host" | head -1))"
    else
        echo "FAIL: $host"
    fi
done
```

#### Practice 10: Package Auditor

```bash
#!/bin/bash
# pkg_audit.sh — Audit installed packages

if command -v dpkg &>/dev/null; then
    echo "Total packages: $(dpkg -l | wc -l)"
    echo "Manually installed: $(apt-mark showmanual | wc -l)"
    echo "Updatable: $(apt list --upgradable 2>/dev/null | grep -c upgradable)"
elif command -v rpm &>/dev/null; then
    echo "Total packages: $(rpm -qa | wc -l)"
fi
```

#### Practice 11: Cron Job Manager

```bash
#!/bin/bash
# cronman.sh — Manage system cron jobs

list_jobs() {
    echo "=== System crontab ==="
    [ -f /etc/crontab ] && cat /etc/crontab

    for dir in /etc/cron.hourly /etc/cron.daily /etc/cron.weekly /etc/cron.monthly; do
        echo "=== $dir ==="
        [ -d "$dir" ] && ls -la "$dir"
    done
}

case "${1:-list}" in
    list) list_jobs ;;
    *) echo "Usage: $0 {list}" ;;
esac
```

#### Practice 12: System Cleanup Script

```bash
#!/bin/bash
# cleanup.sh — System maintenance cleanup

log() { echo "[$(date '+%H:%M:%S')] $1"; }

DRY_RUN=false
[ "${1:-}" = "--dry-run" ] && DRY_RUN=true

clean_journal() {
    log "Cleaning journals older than 7 days..."
    [ "$DRY_RUN" = false ] && journalctl --vacuum-time=7d 2>/dev/null || true
}

clean_apt() {
    if command -v apt-get &>/dev/null; then
        log "Cleaning apt cache..."
        [ "$DRY_RUN" = false ] && { apt-get clean; apt-get autoclean; apt-get autoremove --purge -y; }
    fi
}

clean_logs() {
    log "Truncating old log files..."
    [ "$DRY_RUN" = false ] && find /var/log -name "*.log" -type f -size +100M -exec truncate -s 0 {} \;
}

echo "=== System Cleanup $(date) ==="
clean_journal
clean_apt
clean_logs
log "Cleanup complete"
```

### Level 3 Practices: Advanced Scripting

#### Practice 13: Configuration Backup Script

Back up all configs from `/etc/`:
- Only changed files (compare with package manager checksums)
- Version-controlled backup (git init in backup dir)
- Include installed packages list
- Include cron jobs, systemd unit files
- Restore function

#### Practice 14: Mail Queue Monitor

```bash
#!/bin/bash
# mailq_monitor.sh — Monitor mail queue

ALERT_THRESHOLD=100
ALERT_EMAIL="postmaster@example.com"

check_mailq() {
    if command -v mailq &>/dev/null; then
        local count
        count=$(mailq 2>/dev/null | tail -1 | awk '{print $5}')
        [ -z "$count" ] && count=0

        echo "Mail queue: $count messages"

        if [ "$count" -ge "$ALERT_THRESHOLD" ]; then
            echo "ALERT: Queue at ${count} (threshold: ${ALERT_THRESHOLD})"
            mailq | mail -s "ALERT: High mail queue (${count}) on $(hostname)" "$ALERT_EMAIL"
        fi
    fi
}

check_mailq
```

#### Practice 15: Real-World Integration — Complete Admin Toolkit

```bash
#!/bin/bash
# sysadmin.sh — Complete System Administration Toolkit
# Usage: sysadmin.sh [command] [options]

set -euo pipefail

VERSION="1.0.0"
CONFIG_DIR="${HOME}/.sysadmin"
LOG_FILE="${CONFIG_DIR}/sysadmin.log"

mkdir -p "$CONFIG_DIR"

log() {
    local level="$1"
    local msg="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [${level}] ${msg}" | tee -a "$LOG_FILE"
}

info()  { log "INFO" "$1"; }
warn()  { log "WARN" "$1"; }
error() { log "ERROR" "$1" >&2; }

cmd_sysinfo() {
    echo "=========================================="
    echo " System Information — $(hostname)"
    echo "=========================================="
    echo "OS:    $(lsb_release -ds 2>/dev/null || cat /etc/os-release 2>/dev/null | grep -m1 PRETTY_NAME | cut -d= -f2- | tr -d '\"')"
    echo "Kernel: $(uname -r)"
    echo "Uptime: $(uptime -p)"
    echo "CPU:   $(nproc) cores, Load: $(uptime | awk -F'load average:' '{print $2}')"
    echo "Memory: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
    echo "Disk:  $(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}')"
}

cmd_backup() {
    local source="${1:?backup: source directory required}"
    local dest="${2:-/var/backups}"
    local name="backup_$(basename "$source")_$(date +%Y%m%d_%H%M%S).tar.gz"
    [ ! -d "$source" ] && { error "Source not found: $source"; return 1; }
    mkdir -p "$dest"
    tar -czf "${dest}/${name}" -C "$(dirname "$source")" "$(basename "$source")"
    info "Backup complete: ${dest}/${name}"
}

cmd_health() {
    echo "=== Health Check: $(hostname) ==="
    local load cores pct
    load=$(awk '{print $1}' /proc/loadavg)
    cores=$(nproc)
    pct=$(echo "$load $cores" | awk '{printf "%.0f", ($1/$2)*100}')
    [ "$pct" -gt 80 ] && warn "CPU: ${pct}% load" || info "CPU: ${pct}% load"
}

cmd_network() {
    echo "=== Network Diagnostics ==="
    echo "Interfaces:"
    ip -br addr show 2>/dev/null | grep -v lo
    echo "Default route:"
    ip route show default 2>/dev/null
    echo "Connectivity:"
    for host in google.com 8.8.8.8; do
        ping -c1 -W2 "$host" &>/dev/null && echo "  ✓ $host reachable" || echo "  ✗ $host unreachable"
    done
}

usage() {
    cat <<EOF
sysadmin.sh v${VERSION} — System Administration Toolkit
Usage: $0 <command> [options]
Commands:
    sysinfo              System information report
    backup <src> [dest]  Backup a directory
    health               System health check
    network              Network diagnostics
    help                 Show this help
EOF
}

cmd="${1:-help}"
shift 2>/dev/null || true

case "$cmd" in
    sysinfo|health|network) "cmd_${cmd}" "$@" ;;
    backup) cmd_backup "$@" ;;
    help|--help|-h) usage ;;
    *) error "Unknown command: $cmd"; usage; exit 1 ;;
esac
```

---

## 17. Self-Test

**Score: 12/15 correct = ready for Part 36.**

### Questions

**Q1.** What does the shebang `#!/bin/bash` do?

**Q2.** What is the difference between `./script.sh` and `source script.sh`?

**Q3.** What does `set -euo pipefail` do? Explain each flag.

**Q4.** Write a one-liner that extracts lines 10-20 from a file.

**Q5.** What is the difference between `[ ]` and `[[ ]]` in bash?

**Q6.** How do you iterate over all `.conf` files in `/etc/`?

**Q7.** What does `${var:-default}` do?

**Q8.** How do you capture the output of a command into a variable?

**Q9.** What is the purpose of `mktemp` and why is it important?

**Q10.** How do you run a command in the background and get its PID?

**Q11.** Write a function that checks if a directory exists and is writable.

**Q12.** What is the difference between `$@` and `$*`?

**Q13.** How does `trap cleanup EXIT` work?

**Q14.** What does `IFS=` do in `while IFS= read -r line`?

**Q15.** How do you create an associative array in bash?

### Answers

**A1.** The shebang tells the kernel which interpreter to use. The kernel reads the first line, finds `/bin/bash`, and executes: `/bin/bash ./script.sh`.

**A2.** `./script.sh` runs in a new child process (fork+exec). `source script.sh` reads and executes the script in the current shell — all variable/function changes persist.

**A3.**
- `-e`: Exit immediately if any command exits with non-zero status
- `-u`: Treat reference to unset variables as an error
- `-o pipefail`: Pipeline fails if ANY command in the pipeline fails (not just the last)

**A4.** `sed -n '10,20p' file` or `awk 'NR>=10 && NR<=20' file`

**A5.** `[ ]` is POSIX `test`, performs word splitting and pathname expansion. `[[ ]]` is a bash keyword, doesn't split words, supports `=~` regex matching, `&&`/`||` operators, and pattern matching.

**A6.** `for file in /etc/*.conf; do echo "$file"; done`

**A7.** `${var:-default}` returns `default` if `$var` is unset or null; otherwise returns the value of `$var`.

**A8.** `output=$(command)`

**A9.** `mktemp` creates a temporary file or directory with a unique, unpredictable name. Prevents race conditions and symlink attacks.

**A10.** `command & pid=$!`

**A11.** `check_dir() { local dir="$1"; [ -d "$dir" -a -w "$dir" ]; }`

**A12.** `$@` expands each positional parameter as a separate word (preserves quoting). `$*` expands to a single word (all parameters concatenated).

**A13.** `trap cleanup EXIT` registers the `cleanup` function to be called automatically when the script exits for any reason.

**A14.** Setting `IFS=` (empty) prevents `read` from stripping leading/trailing whitespace. With `-r`, it safely reads lines without modification.

**A15.** `declare -A myarray; myarray[key1]="value1"; myarray[key2]="value2"`

### Scoring

| Score | Assessment |
|---|---|
| 15/15 | Expert level — you could teach this |
| 12-14/15 | Ready for Part 36 |
| 8-11/15 | Review sections 3-8 and retry |
| 0-7/15 | Re-read this part before moving on |

---

## 18. What's Coming in Part 36

**Part 36: Advanced Shell Scripting — sed, awk, regex**

We'll dive deep into:
- `sed`: stream editing — substitutions, deletions, multi-line operations
- `awk`: pattern scanning — field processing, arrays, report generation
- Regular expressions: BRE vs ERE, lookaheads, backtracking
- Combining sed/awk in pipeline for real admin tasks
- Advanced text processing for log parsing, config generation, data extraction

---

*Previous → Part 34: Process Management*
*Next → Part 36: Advanced Shell Scripting*

[← Previous](part34.md) | [Next →](part36.md)
