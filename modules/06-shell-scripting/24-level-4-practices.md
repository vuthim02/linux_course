## 💻 Level 4 — Mastery Practices

### ✅ Practice 1: Professional Argument Parser with getopts

```bash
cd ~/linux-course/part6

cat > create_user.sh << 'EOF'
#!/bin/bash
set -Eeuo pipefail

VERSION="1.0.0"
VERBOSE=0
GROUPS=()
SHELL="/bin/bash"
HOME_DIR=""

usage() {
  cat << EOF
Usage: $(basename "$0") [options] <username>

Create a system user with custom configuration.

Options:
  -g GROUP   Supplementary groups (comma-separated, can repeat)
  -s SHELL   Login shell (default: /bin/bash)
  -h HOME    Home directory (default: /home/<username>)
  -v         Verbose
  -V         Show version
  -?         Show help
EOF
  exit 0
}

log() { [ "$VERBOSE" -eq 1 ] && echo "$(date '+%H:%M:%S') $*"; }

while getopts "g:s:h:vV?" opt; do
  case "$opt" in
    g) IFS=',' read -ra extra <<< "$OPTARG"
       GROUPS+=("${extra[@]}") ;;
    s) SHELL="$OPTARG" ;;
    h) HOME_DIR="$OPTARG" ;;
    v) VERBOSE=1 ;;
    V) echo "$(basename "$0") $VERSION"; exit 0 ;;
    ?) usage ;;
    *) usage ;;
  esac
done
shift $((OPTIND-1))

[ "$#" -lt 1 ] && echo "Error: username required" >&2 && usage

USERNAME="$1"

log "Creating user $USERNAME..."
sudo useradd -m -s "$SHELL" ${HOME_DIR:+-d "$HOME_DIR"} "$USERNAME"

for group in "${GROUPS[@]}"; do
  log "Adding $USERNAME to group $group"
  sudo usermod -aG "$group" "$USERNAME"
done

log "User $USERNAME created successfully"
EOF

chmod +x create_user.sh
echo "Review the script with: shellcheck create_user.sh"
echo "Try: ./create_user.sh -v -g sudo,docker testuser"
```

### ✅ Practice 2: Debugging a Broken Script

```bash
cd ~/linux-course/part6

cat > broken.sh << 'EOF'
#!/bin/bash
# This script has bugs — find and fix them!
set -euo pipefail

# Bug 1: Unquoted variable
files=$(ls *.txt)
for f in $files; do
  echo "Processing: $f"
done

# Bug 2: Missing error check
rm /nonexistent/file
echo "Cleaned up!"

# Bug 3: Word splitting
args="-la /etc"
ls $args
EOF

echo "=== Debug with bash -x ==="
echo "Run: bash -x broken.sh"
echo ""
echo "=== Debug with ShellCheck ==="
echo "Run: shellcheck broken.sh"
echo ""
echo "=== Fixed version ==="
echo "Use quotes, check errors, use arrays"
echo 'args=(-la /etc); ls "${args[@]}"'
```

### ✅ Practice 3: Process Substitution in Action

```bash
cd ~/linux-course/part6

cat > compare_dirs.sh << 'EOF'
#!/bin/bash
set -euo pipefail

DIR1="${1:-/etc}"
DIR2="${2:-/etc.default}"

echo "=== Files in $DIR1 but not in $DIR2 ==="
comm -23 <(ls "$DIR1" | sort) <(ls "$DIR2" | sort 2>/dev/null)

echo ""
echo "=== Files in BOTH directories ==="
comm -12 <(ls "$DIR1" | sort) <(ls "$DIR2" | sort 2>/dev/null)
EOF

chmod +x compare_dirs.sh
echo "Run: ./compare_dirs.sh /etc /etc"  # self-comparison test
```

### ✅ Practice 4: TUI Menu (Dialog)

```bash
cd ~/linux-course/part6

cat > sys_menu.sh << 'EOF'
#!/bin/bash
set -euo pipefail

require() { command -v "$1" &>/dev/null || { echo "Install $1"; exit 1; }; }
require "dialog"

while true; do
  choice=$(dialog --clear --stdout \
    --title "System Tools" \
    --menu "Select an option:" 15 50 5 \
    1 "Show Disk Usage" \
    2 "Show Memory Usage" \
    3 "Show Running Services" \
    4 "Kill a Process" \
    5 "Exit")

  case "$choice" in
    1) dialog --msgbox "$(df -h 2>&1)" 20 60 ;;
    2) dialog --msgbox "$(free -h 2>&1)" 15 50 ;;
    3) dialog --msgbox "$(systemctl list-units --type=service --state=running --no-legend 2>&1)" 20 70 ;;
    4) pid=$(dialog --stdout --inputbox "Enter PID:" 8 40)
       [ -n "$pid" ] && kill "$pid" 2>/dev/null && dialog --msgbox "Killed PID $pid" 8 40 ;;
    5) clear; break ;;
  esac || break
done
EOF

chmod +x sys_menu.sh
echo "Run: ./sys_menu.sh (requires 'dialog' package)"
```

### ✅ Practice 5: BATS Test Suite

```bash
cd ~/linux-course/part6

# Create a library to test
cat > lib.sh << 'EOF'
#!/bin/bash

is_root() { [[ $(id -u) -eq 0 ]]; }

validate_port() {
  local port="$1"
  [[ "$port" =~ ^[0-9]+$ ]] && ((port >= 1 && port <= 65535))
}

greet() { echo "Hello, ${1:-World}!"; }
EOF

cat > test_lib.bats << 'EOF'
#!/usr/bin/env bats
load lib.sh

@test "is_root returns false for non-root" {
  run is_root
  [ "$status" -eq 1 ]
}

@test "validate_port accepts 80" {
  run validate_port 80
  [ "$status" -eq 0 ]
}

@test "validate_port rejects 0" {
  run validate_port 0
  [ "$status" -eq 1 ]
}

@test "validate_port rejects letters" {
  run validate_port abc
  [ "$status" -eq 1 ]
}

@test "greet says Hello" {
  run greet "Alice"
  [ "$output" = "Hello, Alice!" ]
}
EOF

chmod +x test_lib.bats
echo "Run: bats test_lib.bats"
```



[← Previous](23-section-8-security-and-testing.md) | [↑ Index](index.md) | [Next →](25-rules-of-thumb.md)
