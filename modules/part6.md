# 🐧 Linux System Administrator — Complete Course
## Part 6 of ∞: Shell Scripting — Automate Everything

---

> **Reverse Engineering Approach:** Every command you type manually is a script waiting to be born. If you have typed something twice, you should script it. If you have typed it three times, the script should be on a cron job. We start from the simplest possible script and build up to professional-grade automation tools.

---

## 🎯 What You Will Achieve in Part 6

| Level | What You Will Master |
|-------|---------------------|
| ⭐ **Level 1: Basic** | Write bash scripts from scratch with proper structure. Use variables, conditionals, and command-line arguments. Understand shebang, running vs sourcing, and quoting. |
| ⭐ **Level 2: Intermediary** | Master loops (for, while, until), functions, exit codes, arrays, and file I/O. Build reusable code blocks and process data efficiently. |
| ⭐ **Level 3: Advanced** | Handle errors gracefully with trap and validation. Write professional scripts with getopts, logging, and safety guards. Schedule scripts with cron. Understand the fork-exec model. |

---

# ⭐ Level 1: Basic — Script Fundamentals

![Screenshot of Bourne Again SHell (Bash) terminal](https://upload.wikimedia.org/wikipedia/commons/e/e7/Bash_screenshot.png)
*Screenshot: Bash terminal. Credit: Emx, GPL.*

> **Level 1 Goal:** Write bash scripts from scratch with variables, conditionals, and command-line arguments. Understand shebang, execution methods, and proper quoting.

## 🔍 Section 1: What Is a Shell Script?

A shell script is a **text file containing commands** that bash executes line by line.

```bash
#!/bin/bash
echo "Hello, World!"
```

That is a complete shell script. The `#!` line (called **shebang**) tells the system which interpreter to use.

### The Shebang Explained

```bash
#!/bin/bash       # Use bash
#!/bin/sh         # Use the system shell (might be dash on Debian)
#!/usr/bin/python3 # Use Python
#!/usr/bin/env bash # Use bash wherever it is installed (more portable)
```

> 💡 Always use `#!/bin/bash` for scripts that use bash-specific features (like `[[ ]]`, arrays, `source`). Use `#!/bin/sh` for maximum portability.

### How to Run a Script

```bash
# Method 1: Make executable and run
chmod +x myscript.sh
./myscript.sh

# Method 2: Pass to bash explicitly (no execute permission needed)
bash myscript.sh

# Method 3: Source it (runs in current shell, not a subshell)
source myscript.sh
. myscript.sh        # Same as source
```

### The Difference Between Running and Sourcing

```bash
# Running — creates a subshell:
./script.sh
# Changes to variables/cd are LOST when script ends

# Sourcing — runs in current shell:
source script.sh
# Changes to variables/cd PERSIST after script ends
```

---

## 🔍 Section 2: Variables — Storing Data

### Defining Variables

```bash
# NO spaces around = !!!
name="Alice"
age=30
current_dir=$(pwd)    # Command substitution
files_count=$(ls | wc -l)

# Using variables
echo "$name"
echo "${name}"        # Same, but safer (needed when text follows the variable)
echo "${name}'s age is $age"
```

### Rules for Variable Names

```bash
# Valid:
NAME="Alice"
name="Alice"
my_name="Alice"
_name="Alice"
NAME2="Alice"

# Invalid:
2name="Alice"      # Starts with number
my-name="Alice"    # Hyphen not allowed
my name="Alice"    # Space not allowed
```

### Quoting Matters

```bash
name="Alice Johnson"

# Double quotes: variables are EXPANDED
echo "Hello, $name"    # Hello, Alice Johnson

# Single quotes: variables are LITERAL
echo 'Hello, $name'    # Hello, $name

# No quotes: works but risky (word splitting, glob expansion)
echo Hello, $name      # Works but can break with special chars
```

> 💡 **Always quote your variables.** Use `"$var"` not `$var`. This prevents word splitting and glob expansion.

### readonly and declare

```bash
readonly PI=3.14159    # Cannot be changed later
declare -i count=5     # Integer type (arithmetic, not string)
declare -r API_KEY="abc123"  # Read-only (same as readonly)
declare -a fruits=("apple" "banana")  # Array
declare -A user=([name]="Alice" [age]=30)  # Associative array (bash 4+)
```

### Variable Expansion Tricks

```bash
name="Alice"

# Default values
echo "${name:-Guest}"       # "Alice" if set, "Guest" if unset/null
echo "${name:+present}"     # "present" if set, empty if unset
echo "${name:?error msg}"   # Print error and exit if unset

# String manipulation
echo "${#name}"             # Length: 5
echo "${name:0:3}"          # Substring: "Ali"
echo "${name/l/L}"          # Replace first l with L: "A lice"
echo "${name//l/L}"         # Replace all l with L: "ALice"

# Default assignment
: "${MY_VAR:=default}"     # Sets MY_VAR to "default" if unset
```

---

## 🔍 Section 3: Conditionals — Making Decisions

### if Statement

```bash
if [ condition ]; then
    echo "Condition is true"
elif [ other_condition ]; then
    echo "Other condition is true"
else
    echo "Neither is true"
fi
```

### The `test` Command and `[ ]`

`[` is actually a command (an alias for `test`). It must have spaces around each argument.

```bash
# Numeric comparisons
[ "$count" -eq 5 ]     # Equal to
[ "$count" -ne 5 ]     # Not equal to
[ "$count" -gt 5 ]     # Greater than
[ "$count" -ge 5 ]     # Greater than or equal
[ "$count" -lt 5 ]     # Less than
[ "$count" -le 5 ]     # Less than or equal

# String comparisons
[ "$name" = "Alice" ]  # Equal to (use single =, not ==)
[ "$name" != "Bob" ]   # Not equal
[ -z "$name" ]         # String is empty (zero length)
[ -n "$name" ]         # String is not empty

# File tests
[ -f "$file" ]         # Is a regular file
[ -d "$dir" ]          # Is a directory
[ -e "$path" ]         # Exists (any type)
[ -r "$file" ]         # Is readable
[ -w "$file" ]         # Is writable
[ -x "$file" ]         # Is executable
[ -s "$file" ]         # Is not empty (size > 0)
[ -L "$file" ]         # Is a symbolic link

# Combining conditions
[ "$a" = "$b" ] && [ "$c" = "$d" ]  # AND
[ "$a" = "$b" ] || [ "$c" = "$d" ]  # OR
[ ! -f "$file" ]                     # NOT
```

### The Modern `[[ ]]` Syntax (Bash-specific, Safer)

```bash
# [[ ]] is a bash keyword, not a command. It's safer and more powerful.

# String patterns with wildcards
[[ "$name" = A* ]]      # true if name starts with "A"
[[ "$name" =~ ^A.*s$ ]] # true if matches regex (starts A, ends s)

# No need to quote variables inside [[ ]]
[[ -f $file ]]           # Works even if file has spaces

# Logical operators are simpler
[[ $a = $b && $c = $d ]]  # AND (single &&)
[[ $a = $b || $c = $d ]]  # OR (single ||)
```

> 💡 **Prefer `[[ ]]` over `[ ]`** in bash scripts. It is faster, safer, and more readable.

### case Statement

```bash
case "$1" in
    start)
        echo "Starting..."
        ;;
    stop)
        echo "Stopping..."
        ;;
    restart|reload)
        echo "Restarting..."
        ;;
    *)
        echo "Usage: $0 {start|stop|restart}"
        exit 1
        ;;
esac
```

---

## 🔍 Section 4: Arguments and Parameters

### Reading Script Arguments

```bash
#!/bin/bash
# Save as args.sh

echo "Script name: $0"
echo "First argument: $1"
echo "Second argument: $2"
echo "All arguments: $@"
echo "Number of arguments: $#"
```

```bash
$ ./args.sh foo bar baz
# Script name: ./args.sh
# First argument: foo
# Second argument: bar
# All arguments: foo bar baz
# Number of arguments: 3
```

### Shifting Arguments

```bash
#!/bin/bash
# Use shift to process arguments one by one

while [ "$#" -gt 0 ]; do
    echo "Processing: $1"
    shift
done
```

---

## 💻 Level 1 Practices

### ✅ Practice 1: Your First Script

```bash
mkdir -p ~/linux-course/part6
cd ~/linux-course/part6

# Create and save this as hello.sh:
cat > hello.sh << 'EOF'
#!/bin/bash
echo "Hello, Linux SysAdmin!"
echo "Today is $(date)"
echo "You are logged in as $(whoami)"
EOF

chmod +x hello.sh
./hello.sh
```

---

### ✅ Practice 2: Variables

```bash
cd ~/linux-course/part6

cat > variables.sh << 'EOF'
#!/bin/bash
name="Alice"
age=30
hostname=$(hostname)

echo "Name: $name"
echo "Age: $age"
echo "Hostname: $hostname"
echo "Script: $0"
EOF

chmod +x variables.sh
./variables.sh
```

---

### ✅ Practice 3: User Input

```bash
cd ~/linux-course/part6

cat > greet.sh << 'EOF'
#!/bin/bash
read -p "What is your name? " name
read -p "How old are you? " age

echo "Hello, $name!"
echo "In 10 years you will be $((age + 10))."
EOF

chmod +x greet.sh
./greet.sh
```

---

### ✅ Practice 4: Conditionals

```bash
cd ~/linux-course/part6

cat > check_file.sh << 'EOF'
#!/bin/bash

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <filename>"
    exit 1
fi

file="$1"

if [ -f "$file" ]; then
    echo "$file exists and is a regular file."
    echo "Size: $(stat -c%s "$file") bytes"
elif [ -d "$file" ]; then
    echo "$file is a directory."
    echo "Contents: $(ls "$file" | wc -l) items"
elif [ -e "$file" ]; then
    echo "$file exists (but is not a regular file or directory)."
else
    echo "$file does not exist."
    exit 1
fi
EOF

chmod +x check_file.sh
./check_file.sh /etc/hosts
./check_file.sh /etc
./check_file.sh /nonexistent
```

---

### ✅ Practice 5: Command-Line Arguments

```bash
cd ~/linux-course/part6

cat > args_demo.sh << 'EOF'
#!/bin/bash

echo "Script: $0"
echo "First arg: $1"
echo "Second arg: $2"
echo "All args: $@"
echo "Arg count: $#"

echo ""
echo "Iterating through all arguments:"
count=1
for arg in "$@"; do
    echo "  Arg $count: $arg"
    ((count++))
done
EOF

chmod +x args_demo.sh
./args_demo.sh one two three four
```

---

# ⭐ Level 2: Intermediary — Control Flow and Data Structures

![Linux command-line in GNOME Terminal showing Bash](https://upload.wikimedia.org/wikipedia/commons/2/29/Linux_command-line._Bash._GNOME_Terminal._screenshot.png)
*Screenshot: Linux command line in GNOME Terminal. Credit: Wikimedia Commons user, GPL.*

> **Level 2 Goal:** Master loops, functions, exit codes, arrays, and file I/O to build reusable and data-processing scripts.

## 🔍 Section 1: Loops — Doing Things Repeatedly

### for Loop — Iterate Over a List

```bash
# Over explicit list
for fruit in apple banana cherry; do
    echo "Fruit: $fruit"
done

# Over wildcard expansion
for file in /etc/*.conf; do
    echo "Config: $file"
done

# C-style for loop (like C/Java)
for ((i=0; i<10; i++)); do
    echo "Iteration: $i"
done

# Over command output
for user in $(awk -F: '$3 >= 1000 {print $1}' /etc/passwd); do
    echo "User: $user"
done
```

### while Loop — Loop Until Condition Is False

```bash
# Read a file line by line
while IFS= read -r line; do
    echo "Line: $line"
done < /etc/hosts

# Infinite loop with break condition
count=0
while true; do
    echo "Count: $count"
    ((count++))
    [ "$count" -ge 5 ] && break
done

# Watch a process until it finishes
while pgrep -x "apt" > /dev/null; do
    echo "apt is still running..."
    sleep 2
done
echo "apt has finished."
```

### until Loop — Loop Until Condition Is True

```bash
count=0
until [ "$count" -ge 5 ]; do
    echo "Count: $count"
    ((count++))
done
```

### Loop Control

```bash
break       # Exit the loop immediately
continue    # Skip to next iteration
break 2     # Exit 2 levels of nested loops
```

---

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

---

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

## 🔍 Section 4: Arrays — Multiple Values in One Variable

```bash
# Define an array
fruits=("apple" "banana" "cherry" "date")

# Access elements
echo "${fruits[0]}"   # apple
echo "${fruits[1]}"   # banana
echo "${fruits[-1]}"  # date (last element)

# All elements
echo "${fruits[@]}"    # apple banana cherry date
echo "${fruits[*]}"    # Same, but with IFS joining

# Length
echo "${#fruits[@]}"   # 4

# Loop through array
for fruit in "${fruits[@]}"; do
    echo "Fruit: $fruit"
done

# Add elements
fruits+=("elderberry" "fig")

# Slice
echo "${fruits[@]:1:2}"  # banana cherry

# Associative arrays (bash 4+)
declare -A user
user[name]="Alice"
user[age]=30
user[role]="admin"

echo "${user[name]}"   # Alice
```

---

## 🔍 Section 5: Input and Output in Scripts

### Reading User Input

```bash
#!/bin/bash

read -p "Enter your name: " username
echo "Hello, $username!"

# Read with timeout (seconds)
read -t 5 -p "Quick, enter something (5 sec): " input

# Read password (no echo)
read -s -p "Enter password: " password
echo

# Read into array
read -a numbers -p "Enter three numbers: "
echo "First: ${numbers[0]}"
```

### Reading From a File

```bash
#!/bin/bash

# Method 1: Read line by line (best for large files)
while IFS= read -r line; do
    echo "Line: $line"
done < /etc/hosts

# Method 2: Read file into variable (small files only)
content=$(cat /etc/hosts)
echo "$content"

# Method 3: Read file into array
mapfile -t lines < /etc/hosts
echo "Total lines: ${#lines[@]}"
echo "First line: ${lines[0]}"
```

### Redirecting Output From Within the Script

```bash
#!/bin/bash

# Redirect ALL output of a function or section
{
    echo "Starting backup..."
    date
    rsync -avz /data /backup/
    echo "Backup complete"
} > backup.log 2>&1

# Or use exec at the top
exec > script.log 2>&1
echo "Everything goes to the log file"
```

---

## 💻 Level 2 Practices

### ✅ Practice 1: for Loop

```bash
cd ~/linux-course/part6

cat > list_confs.sh << 'EOF'
#!/bin/bash

echo "Configuration files in /etc:"
count=0
for file in /etc/*.conf; do
    if [ -f "$file" ]; then
        echo "  $file"
        ((count++))
    fi
done
echo "Total: $count .conf files"
EOF

chmod +x list_confs.sh
./list_confs.sh
```

---

### ✅ Practice 2: while Loop

```bash
cd ~/linux-course/part6

cat > watch_process.sh << 'EOF'
#!/bin/bash

process_name="$1"
if [ -z "$process_name" ]; then
    echo "Usage: $0 <process_name>"
    exit 1
fi

echo "Watching for process: $process_name"
echo "Press Ctrl+C to stop."

while true; do
    if pgrep -x "$process_name" > /dev/null; then
        echo "$(date): $process_name is RUNNING"
    else
        echo "$(date): $process_name is NOT running"
    fi
    sleep 2
done
EOF

chmod +x watch_process.sh
# Run briefly: ./watch_process.sh bash
# Press Ctrl+C to stop
```

---

### ✅ Practice 3: Exit Codes

```bash
cd ~/linux-course/part6

cat > check_root.sh << 'EOF'
#!/bin/bash

if [ "$(id -u)" -eq 0 ]; then
    echo "Running as root"
    exit 0
else
    echo "Not running as root" >&2
    exit 1
fi
EOF

chmod +x check_root.sh
./check_root.sh
echo "Exit code: $?"
```

---

### ✅ Practice 4: Functions

```bash
cd ~/linux-course/part6

cat > functions.sh << 'EOF'
#!/bin/bash

# Color output functions
info()    { echo -e "\033[1;34m[INFO]\033[0m $1"; }
success() { echo -e "\033[1;32m[OK]\033[0m $1"; }
warning() { echo -e "\033[1;33m[WARN]\033[0m $1"; }
error()   { echo -e "\033[1;31m[ERROR]\033[0m $1" >&2; }

# Use them
info "System check started"
if [ -d /etc ]; then
    success "/etc exists"
else
    error "/etc does not exist"
fi
warning "This is a warning message"
info "System check complete"
EOF

chmod +x functions.sh
./functions.sh
```

---

### ✅ Practice 5: Arrays

```bash
cd ~/linux-course/part6

cat > arrays.sh << 'EOF'
#!/bin/bash

# Define array of users
users=("alice" "bob" "charlie" "diana")

echo "All users: ${users[@]}"
echo "First user: ${users[0]}"
echo "Last user: ${users[-1]}"
echo "Number of users: ${#users[@]}"

echo ""
echo "Looping through users:"
for user in "${users[@]}"; do
    echo "  User: $user"
done

echo ""
echo "Adding a user..."
users+=("eve")
echo "Now ${#users[@]} users: ${users[@]}"
EOF

chmod +x arrays.sh
./arrays.sh
```

---

### ✅ Practice 6: Read From File

```bash
cd ~/linux-course/part6

# Create a data file
cat > users.txt << 'EOF'
alice:1001:Alice Johnson
bob:1002:Bob Smith
charlie:1003:Charlie Brown
EOF

cat > read_file.sh << 'EOF'
#!/bin/bash

if [ ! -f "$1" ]; then
    echo "Usage: $0 <file>"
    exit 1
fi

echo "Reading file: $1"
echo "---"

while IFS=: read -r username uid fullname; do
    echo "User: $username"
    echo "  UID: $uid"
    echo "  Name: $fullname"
    echo "---"
done < "$1"
EOF

chmod +x read_file.sh
./read_file.sh users.txt
```

---

# ⭐ Level 3: Advanced — Professional Scripts and Automation

![Crontab file being edited in terminal showing scheduled jobs](https://upload.wikimedia.org/wikipedia/commons/f/fa/Crontab.png)
*Screenshot: Crontab editor. Credit: Wikimedia Commons user, GPL.*

> **Level 3 Goal:** Write professional scripts with error handling, argument parsing, logging, and safety guards. Schedule scripts with cron. Understand the fork-exec model and environment inheritance.

## 🔍 Section 1: Error Handling — Writing Safe Scripts

### Trap — Catch Errors and Clean Up

```bash
#!/bin/bash
set -euo pipefail

# Cleanup function — runs on exit
cleanup() {
    echo "Cleaning up..."
    rm -rf /tmp/mytemp.$$
    echo "Done."
}

# Trap EXIT signal (runs when script exits for ANY reason)
trap cleanup EXIT

# Trap specific signals
trap 'echo "Interrupted!"; exit 1' INT TERM

# Main script
echo "Working..."
mkdir -p /tmp/mytemp.$$
sleep 10
echo "Done working."
```

### Checking for Required Commands

```bash
#!/bin/bash

# Check if required commands exist
for cmd in rsync ssh tar gzip; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "Error: $cmd is not installed." >&2
        exit 1
    fi
done

echo "All required commands are available."
```

### Validating Arguments

```bash
#!/bin/bash

# Check number of arguments
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <source_dir> <backup_dir>" >&2
    exit 1
fi

# Check if source exists
if [ ! -d "$1" ]; then
    echo "Error: Source directory '$1' does not exist." >&2
    exit 1
fi

# Check if backup directory is writable
if [ ! -w "$(dirname "$2")" ]; then
    echo "Error: Cannot write to '$2'." >&2
    exit 1
fi

echo "All validations passed."
```

---

## 🔍 Section 2: Professional Script Template

```bash
#!/bin/bash
#=======================================================================
# Script:     backup.sh
# Author:     Your Name
# Date:       2024-01-15
# Description: Backup important directories to /backup
# Usage:      ./backup.sh [options]
# Options:    -v       Verbose output
#             -d DIR   Directory to backup (default: /home)
#             -o FILE  Output log file
#=======================================================================

set -Eeuo pipefail

#--- Constants ---
SCRIPT_NAME=$(basename "$0")
VERSION="1.0.0"

#--- Config ---
VERBOSE=0
BACKUP_DIR="/backup"
SOURCE_DIR="/home"
LOG_FILE=""

#--- Functions ---
usage() {
    cat << EOF
Usage: $SCRIPT_NAME [options]

Options:
    -v          Verbose mode
    -d DIR      Directory to backup (default: $SOURCE_DIR)
    -o FILE     Log file
    -h          Show this help

Version: $VERSION
EOF
    exit 0
}

log() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    if [ -n "$LOG_FILE" ]; then
        echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    fi
    
    if [ "$VERBOSE" -eq 1 ] || [ "$level" = "ERROR" ]; then
        echo "[$timestamp] [$level] $message" >&2
    fi
}

cleanup() {
    log "INFO" "Cleaning up temporary files..."
    # Add cleanup code here
    log "INFO" "Script finished."
}

check_dependencies() {
    local deps=("rsync" "tar" "gzip")
    for cmd in "${deps[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            log "ERROR" "Required command '$cmd' not found."
            exit 1
        fi
    done
}

do_backup() {
    local src="$1"
    local dest="$2"
    local timestamp
    timestamp=$(date '+%Y%m%d_%H%M%S')
    local archive="backup_$(basename "$src")_$timestamp.tar.gz"
    
    log "INFO" "Starting backup of $src"
    
    if [ ! -d "$src" ]; then
        log "ERROR" "Source directory '$src' does not exist."
        return 1
    fi
    
    mkdir -p "$dest"
    
    tar -czf "$dest/$archive" -C "$(dirname "$src")" "$(basename "$src")"
    
    log "INFO" "Backup created: $dest/$archive"
    return 0
}

#--- Main ---

# Set up trap
trap cleanup EXIT

# Parse arguments
while getopts "vd:o:h" opt; do
    case "$opt" in
        v) VERBOSE=1 ;;
        d) SOURCE_DIR="$OPTARG" ;;
        o) LOG_FILE="$OPTARG" ;;
        h) usage ;;
        *) usage ;;
    esac
done

# Check dependencies
check_dependencies

# Run backup
do_backup "$SOURCE_DIR" "$BACKUP_DIR"
```

### Parsing Options With getopts

```bash
#!/bin/bash

usage() {
    echo "Usage: $0 [-v] [-o output_file] [-n count] name"
    exit 1
}

verbose=0
output=""
count=1

while getopts "vo:n:" opt; do
    case "$opt" in
        v) verbose=1 ;;
        o) output="$OPTARG" ;;
        n) count="$OPTARG" ;;
        *) usage ;;
    esac
done

shift $((OPTIND-1))

if [ "$#" -lt 1 ]; then
    usage
fi

name="$1"
echo "Name: $name, Count: $count, Output: $output, Verbose: $verbose"
```

```bash
$ ./script.sh -v -o report.txt -n 5 Alice
# Name: Alice, Count: 5, Output: report.txt, Verbose: 1
```

---

## 🔍 Section 3: Scheduling Scripts With cron

```bash
# Edit cron jobs
crontab -e

# List cron jobs
crontab -l

# Remove all cron jobs
crontab -r
```

### Crontab Syntax

```
# ┌────────── minute (0-59)
# │ ┌────────── hour (0-23)
# │ │ ┌────────── day of month (1-31)
# │ │ │ ┌────────── month (1-12)
# │ │ │ │ ┌────────── day of week (0-7, 0=Sun, 7=Sun)
# │ │ │ │ │
# * * * * * command_to_run
```

### Examples

```bash
# Every day at 2:30 AM
30 2 * * * /home/alice/scripts/backup.sh

# Every hour
0 * * * * /home/alice/scripts/check_disk.sh

# Every Monday at 3 AM
0 3 * * 1 /home/alice/scripts/weekly_report.sh

# Every 15 minutes
*/15 * * * * /home/alice/scripts/monitor.sh

# Twice a day (6 AM and 6 PM)
0 6,18 * * * /home/alice/scripts/sync.sh

# First day of every month at midnight
0 0 1 * * /home/alice/scripts/monthly_cleanup.sh
```

### Cron Best Practices

```bash
# Always use FULL PATHS in cron scripts
# Cron has a minimal PATH

# Bad:
0 2 * * * backup.sh  # Will fail — command not found

# Good:
0 2 * * * /home/alice/scripts/backup.sh

# Better: set PATH in the script itself
# In script:
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Redirect output to log
0 2 * * * /home/alice/scripts/backup.sh >> /var/log/backup.log 2>&1

# Use absolute paths for EVERYTHING in cron
```

---

## 🧠 Deep Understanding — How Scripts Execute

### The Fork-Exec Process

When you run `./script.sh`, here is exactly what happens:

```
1. Shell reads the shebang line: #!/bin/bash
2. Shell forks a child process
3. Child process executes exec("./script.sh")
4. Kernel sees the shebang line
5. Kernel runs /bin/bash with the script as argument
6. Bash reads the script line by line
7. For each external command, bash forks again
8. Child runs the external command
9. Child exits, parent (bash) continues
10. When all lines done, bash exits
```

### Why Source Is Different

```bash
# Running: creates subshell
./script.sh

# Sourcing: NO subshell
source script.sh
source script.sh
. script.sh      # Same thing
```

When you `source` a script, the commands run in the **current shell**. Variables, directory changes, and function definitions persist after the script ends.

### The Environment

When bash starts a script, it inherits the **environment** but not the shell variables:

```bash
# In terminal:
MYVAR="hello"
export MYEXPORT="world"

# In script:
echo "$MYVAR"      # Empty! Not exported to child
echo "$MYEXPORT"   # "world" — exported variables are passed
```

To pass a variable to a script:

```bash
# Export it
export MYVAR="hello"
./script.sh

# Or set it inline (for that one command only)
MYVAR="hello" ./script.sh
```

---

## 💻 Level 3 Practices

### ✅ Practice 1: Error Handling With trap

```bash
cd ~/linux-course/part6

cat > safe_script.sh << 'EOF'
#!/bin/bash
set -euo pipefail

cleanup() {
    echo "Cleaning up..."
    if [ -d /tmp/mytempdir ]; then
        rm -rf /tmp/mytempdir
        echo "Removed temp directory"
    fi
    echo "Exiting."
}

trap cleanup EXIT

echo "Creating temp directory..."
mkdir -p /tmp/mytempdir
echo "Working..."
# Simulate some work
sleep 2
echo "Done."
EOF

chmod +x safe_script.sh
./safe_script.sh
```

---

### ✅ Practice 2: Real Script — System Info Report

```bash
cd ~/linux-course/part6

cat > sysinfo.sh << 'EOF'
#!/bin/bash
set -euo pipefail

echo "=================================="
echo "  SYSTEM INFORMATION REPORT"
echo "=================================="
echo "Hostname:  $(hostname)"
echo "Kernel:    $(uname -r)"
echo "Uptime:    $(uptime -p)"
echo "CPU:       $(nproc) cores"
echo "Memory:    $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
echo "Disk:      $(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}')"
echo "Users:     $(who | wc -l) logged in"
echo "Processes: $(ps aux | wc -l)"
echo "=================================="
EOF

chmod +x sysinfo.sh
./sysinfo.sh
```

---

### ✅ Practice 3: Real Script — Disk Usage Alert

```bash
cd ~/linux-course/part6

cat > disk_alert.sh << 'EOF'
#!/bin/bash

THRESHOLD=80

echo "Checking disk usage (threshold: ${THRESHOLD}%)..."
echo ""

df -h | awk -v threshold="$THRESHOLD" '
NR==1 {print; next}
{
    usage = $5
    gsub(/%/, "", usage)
    if (usage >= threshold) {
        printf "\033[1;31mWARNING\033[0m %s is at %s\n", $6, $5
    }
}
'
EOF

chmod +x disk_alert.sh
./disk_alert.sh
```

---

### ✅ Practice 4: Real Script — Backup Directory

```bash
cd ~/linux-course/part6

cat > backup_dir.sh << 'EOF'
#!/bin/bash
set -euo pipefail

SOURCE="${1:-}"
DEST="${2:-/tmp/backup}"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')

if [ -z "$SOURCE" ]; then
    echo "Usage: $0 <source_directory> [destination_directory]"
    exit 1
fi

if [ ! -d "$SOURCE" ]; then
    echo "Error: $SOURCE is not a directory."
    exit 1
fi

mkdir -p "$DEST"

BASENAME=$(basename "$SOURCE")
ARCHIVE="${DEST}/${BASENAME}_${TIMESTAMP}.tar.gz"

echo "Backing up $SOURCE to $ARCHIVE..."
tar -czf "$ARCHIVE" -C "$(dirname "$SOURCE")" "$BASENAME"

echo "Done. Archive size: $(du -h "$ARCHIVE" | cut -f1)"
EOF

chmod +x backup_dir.sh
mkdir -p /tmp/test_backup_source
touch /tmp/test_backup_source/{file1,file2,file3}.txt
./backup_dir.sh /tmp/test_backup_source /tmp/backup_test
ls -la /tmp/backup_test/
```

---

### ✅ Practice 5: Real Script — User Audit

```bash
cd ~/linux-course/part6

cat > user_audit.sh << 'EOF'
#!/bin/bash

echo "=== USER ACCOUNT AUDIT ==="
echo ""

echo "--- Regular Users (UID >= 1000) ---"
awk -F: '$3 >= 1000 {printf "  %-15s UID=%-5s Home=%-20s Shell=%s\n", $1, $3, $6, $7}' /etc/passwd

echo ""
echo "--- Users with Login Access ---"
grep -v '/sbin/nologin\|/bin/false' /etc/passwd | awk -F: '{print "  " $1}'

echo ""
echo "--- Users in sudo/wheel group ---"
for group in sudo wheel; do
    if grep -q "^$group:" /etc/group 2>/dev/null; then
        members=$(grep "^$group:" /etc/group | cut -d: -f4)
        [ -n "$members" ] && echo "  $group: $members" || echo "  $group: (no members)"
    fi
done

echo ""
echo "--- Last Login ---"
last -10 2>/dev/null || echo "  (no login history)"
EOF

chmod +x user_audit.sh
./user_audit.sh
```

---

### ✅ Practice 6: Real Script — Service Manager

```bash
cd ~/linux-course/part6

cat > service_ctl.sh << 'EOF'
#!/bin/bash

SERVICE_NAME="${1:-}"
ACTION="${2:-status}"

usage() {
    echo "Usage: $0 <service_name> {start|stop|restart|status|enable|disable}"
    exit 1
}

[ -z "$SERVICE_NAME" ] && usage

case "$ACTION" in
    start|stop|restart|status|enable|disable)
        echo "Running: systemctl $ACTION $SERVICE_NAME"
        sudo systemctl "$ACTION" "$SERVICE_NAME"
        ;;
    *)
        usage
        ;;
esac
EOF

chmod +x service_ctl.sh
# Test with: ./service_ctl.sh ssh status
```

---

### ✅ Practice 7: Real Script — Log Rotator (Simple)

```bash
cd ~/linux-course/part6

cat > rotate_logs.sh << 'EOF'
#!/bin/bash
set -euo pipefail

LOG_DIR="${1:-/var/log}"
MAX_AGE_DAYS="${2:-7}"

echo "Rotating logs in $LOG_DIR older than $MAX_AGE_DAYS days..."
echo ""

find "$LOG_DIR" -name "*.log" -type f -mtime "+$MAX_AGE_DAYS" -print | while read -r logfile; do
    gzip "$logfile"
    echo "  Compressed: $logfile"
done

echo ""
echo "Done. Run 'ls -la $LOG_DIR/*.gz' to see compressed files."
EOF

chmod +x rotate_logs.sh
mkdir -p /tmp/test_logs
touch -t 202301010000 /tmp/test_logs/old.log
touch /tmp/test_logs/new.log
./rotate_logs.sh /tmp/test_logs 7
ls -la /tmp/test_logs/
```

---

### ✅ Practice 8: Script With getopts

```bash
cd ~/linux-course/part6

cat > report_generator.sh << 'EOF'
#!/bin/bash
set -euo pipefail

verbose=0
output=""
format="text"

usage() {
    cat << EOF
Usage: $(basename "$0") [-v] [-o output_file] [-f format] <directory>

Generate a report of the specified directory.

Options:
    -v          Verbose output
    -o FILE     Write report to FILE (default: stdout)
    -f FORMAT   Output format: text|json (default: text)
    -h          Show this help
EOF
    exit 0
}

while getopts "vo:f:h" opt; do
    case "$opt" in
        v) verbose=1 ;;
        o) output="$OPTARG" ;;
        f) format="$OPTARG" ;;
        h) usage ;;
        *) usage ;;
    esac
done

shift $((OPTIND-1))

target="${1:-.}"
if [ ! -d "$target" ]; then
    echo "Error: '$target' is not a directory" >&2
    exit 1
fi

generate_report() {
    local dir="$1"
    local fmt="$2"
    
    case "$fmt" in
        text)
            cat << REPORT
Directory: $dir
Files:     $(find "$dir" -type f | wc -l)
Dirs:      $(find "$dir" -type d | wc -l)
Size:      $(du -sh "$dir" | cut -f1)
REPORT
            ;;
        json)
            cat << REPORT
{
    "directory": "$dir",
    "files": $(find "$dir" -type f | wc -l),
    "directories": $(find "$dir" -type d | wc -l),
    "size": "$(du -sh "$dir" | cut -f1)"
}
REPORT
            ;;
    esac
}

if [ -n "$output" ]; then
    generate_report "$target" "$format" > "$output"
    [ "$verbose" -eq 1 ] && echo "Report written to $output"
else
    generate_report "$target" "$format"
fi
EOF

chmod +x report_generator.sh
./report_generator.sh /etc
./report_generator.sh -f json /etc
./report_generator.sh -v -o /tmp/report.txt ~/linux-course
cat /tmp/report.txt
```

---

### ✅ Practice 9: Comprehensive Script — System Health Check

```bash
cd ~/linux-course/part6

cat > health_check.sh << 'EOF'
#!/bin/bash
set -Eeuo pipefail

VERSION="1.0.0"
VERBOSE=0
EMAIL=""

# Colors
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

usage() {
    cat << EOF
Usage: $(basename "$0") [options]

System health check tool.

Options:
    -v          Verbose mode
    -e EMAIL    Send report to email
    -h          Show help

Version: $VERSION
EOF
    exit 0
}

log() {
    local level="$1"
    local msg="$2"
    local color=""
    
    case "$level" in
        OK)   color="$GREEN" ;;
        WARN) color="$YELLOW" ;;
        FAIL) color="$RED" ;;
    esac
    
    echo -e "${color}[$level]${NC} $msg"
}

check_cpu() {
    local load
    load=$(uptime | awk -F'load average:' '{print $2}' | cut -d, -f1 | tr -d ' ')
    local cores
    cores=$(nproc)
    
    local threshold=$(echo "$cores * 0.8" | bc)
    if (( $(echo "$load > $threshold" | bc -l) )); then
        log "WARN" "CPU load high: $load (cores: $cores)"
    else
        log "OK" "CPU load normal: $load (cores: $cores)"
    fi
}

check_memory() {
    local total used percent
    total=$(free -m | awk '/^Mem:/ {print $2}')
    used=$(free -m | awk '/^Mem:/ {print $3}')
    percent=$((used * 100 / total))
    
    if [ "$percent" -gt 90 ]; then
        log "FAIL" "Memory critical: ${used}MB/${total}MB (${percent}%)"
    elif [ "$percent" -gt 75 ]; then
        log "WARN" "Memory high: ${used}MB/${total}MB (${percent}%)"
    else
        log "OK" "Memory normal: ${used}MB/${total}MB (${percent}%)"
    fi
}

check_disk() {
    df -h | awk 'NR>1 {
        usage = $5
        gsub(/%/, "", usage)
        mount = $6
        if (usage >= 90)
            printf "'"$RED"'" "[FAIL]"'"$NC"' " %s at %s\n", mount, $5
        else if (usage >= 75)
            printf "'"$YELLOW"'" "[WARN]"'"$NC"' " %s at %s\n", mount, $5
    }'
}

check_services() {
    local services=("sshd" "cron" "rsyslog" "systemd-journald")
    
    for svc in "${services[@]}"; do
        if systemctl is-active --quiet "$svc" 2>/dev/null; then
            log "OK" "Service $svc is running"
        else
            log "WARN" "Service $svc is NOT running"
        fi
    done
}

check_updates() {
    if command -v apt &> /dev/null; then
        local updates
        updates=$(apt list --upgradable 2>/dev/null | wc -l)
        if [ "$updates" -gt 1 ]; then
            log "WARN" "$((updates - 1)) package updates available"
        else
            log "OK" "System is up to date"
        fi
    else
        log "WARN" "Cannot check updates (not apt-based)"
    fi
}

# Parse arguments
while getopts "ve:h" opt; do
    case "$opt" in
        v) VERBOSE=1 ;;
        e) EMAIL="$OPTARG" ;;
        h) usage ;;
        *) usage ;;
    esac
done

# Main
echo ""
echo "============================================"
echo "  SYSTEM HEALTH CHECK"
echo "  Hostname: $(hostname)"
echo "  Date:     $(date)"
echo "============================================"
echo ""

report=$(cat << REPORT
System Health Check Report
==========================
Hostname: $(hostname)
Date:     $(date)

CPU:
$(uptime)

Memory:
$(free -h)

Disk:
$(df -h)

Services:
$(systemctl list-units --type=service --state=running --no-legend | awk '{print "  " $1}')
REPORT
)

check_cpu
check_memory
check_disk
check_services
check_updates

echo ""
echo "============================================"

if [ -n "$EMAIL" ]; then
    echo "$report" | mail -s "Health Report: $(hostname) - $(date)" "$EMAIL"
    log "OK" "Report sent to $EMAIL"
fi
EOF

chmod +x health_check.sh
./health_check.sh
```

---

## 📋 Summary — Complete Command Reference

### Level 1: Basic Commands

**Shebang and Execution**

| Syntax | Purpose |
|--------|---------|
| `#!/bin/bash` | Shebang for bash |
| `#!/usr/bin/env bash` | Portable shebang |
| `chmod +x file && ./file` | Execute script |
| `bash file` | Run with bash explicitly |
| `source file` or `. file` | Run in current shell |

**Variables**

| Code | Purpose |
|------|---------|
| `name="value"` | Assign variable |
| `"$var"` | Use variable (always quote) |
| `${var:-default}` | Default if unset |
| `${#var}` | String length |
| `${var:offset:len}` | Substring |
| `${var/old/new}` | Replace first match |
| `${var//old/new}` | Replace all matches |
| `readonly var` | Make read-only |

**Conditionals**

| Code | Purpose |
|------|---------|
| `[ condition ]` | Test (old syntax) |
| `[[ condition ]]` | Test (new bash, safer) |
| `-f file` | Is regular file |
| `-d dir` | Is directory |
| `-e path` | Exists |
| `-z string` | Is empty |
| `-n string` | Is not empty |
| `=~ regex` | Regex match |
| `&&` | AND |
| `\|\|` | OR |

---

### Level 2: Intermediary Commands

**Loops**

| Code | Purpose |
|------|---------|
| `for i in list; do done` | Iterate |
| `for ((i=0; i<n; i++)); do done` | C-style loop |
| `while condition; do done` | While true |
| `until condition; do done` | Until true |
| `break` | Exit loop |
| `continue` | Next iteration |

**Functions**

| Code | Purpose |
|------|---------|
| `func() { ... }` | Define function |
| `local var` | Local variable in function |
| `return N` | Return exit code |

**Input/Output**

| Code | Purpose |
|------|---------|
| `read var` | Read user input |
| `read -p "prompt" var` | Read with prompt |
| `read -s var` | Read silently (password) |
| `read -t 5 var` | Read with timeout |
| `while IFS= read -r line; do done < file` | Read file line by line |

**Arrays**

| Code | Purpose |
|------|---------|
| `arr=(a b c)` | Create array |
| `"${arr[0]}"` | First element |
| `"${arr[@]}"` | All elements |
| `"${#arr[@]}"` | Array length |
| `arr+=(d)` | Append element |
| `declare -A map` | Associative array |

---

### Level 3: Advanced Commands

**Script Safety**

| Code | Purpose |
|------|---------|
| `set -e` | Exit on error |
| `set -u` | Error on undefined var |
| `set -o pipefail` | Fail on pipe error |
| `set -Eeuo pipefail` | Full safety |
| `trap cmd EXIT` | Run on exit |
| `trap cmd INT TERM` | Run on interrupt |

**getopts**

| Code | Purpose |
|------|---------|
| `getopts "vo:n:" opt` | Parse options |
| `$OPTARG` | Option argument value |
| `shift $((OPTIND-1))` | Remove processed options |

**Cron**

| Code | Purpose |
|------|---------|
| `crontab -e` | Edit cron jobs |
| `crontab -l` | List cron jobs |
| `crontab -r` | Remove all jobs |

---

## 🚀 What's Coming in Part 7

**Part 7: Finding Things — grep, find, locate, and Beyond**

You will learn:
- `grep` — search file contents with patterns
- Regular expressions — the pattern language
- `find` — advanced file searching
- `locate` — searching by filename database
- `ack`, `ag`, `ripgrep` — modern alternatives
- Combining search tools in pipelines
- 15 hands-on practices

---

## 📝 Self-Test — Can You Answer These?

1. What does the shebang `#!/bin/bash` do?
2. What is the difference between `./script.sh` and `source script.sh`?
3. Why should you always quote variables like `"$var"`?
4. What does `set -euo pipefail` do?
5. How do you read a file line by line in bash?
6. What is the difference between `[ ]` and `[[ ]]`?
7. How do you define a function and declare a local variable inside it?
8. What exit code indicates success? What indicates failure?
9. How do you pass a default value if a variable is unset?
10. Write a for loop that iterates over all `.txt` files in the current directory.
11. What does `trap cleanup EXIT` do?
12. How do you schedule a script to run every day at 3:30 AM?
13. What is the difference between running a script and sourcing it?
14. How would you write a function that logs a timestamped message?
15. How do you check if a file exists before operating on it?

**Score:** 12/15 correct = ready for Part 7.

---

*Linux SysAdmin Course | Part 6 of ∞ | Reverse Engineering Approach*
*Previous → Part 5: Pipes, Redirection, and Streams*
*Next → Part 7: Finding Things — grep, find, locate, and Beyond*

[← Previous](part5.md) | [Next →](part7.md)
