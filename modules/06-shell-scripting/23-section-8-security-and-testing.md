## 🔍 Section 8: Security, Linting, and Testing Bash Scripts

### ShellCheck — Static Analysis for Bash

```bash
# Install
sudo apt install shellcheck       # Debian/Ubuntu
sudo dnf install shellcheck        # Fedora/RHEL
brew install shellcheck            # macOS

# Run
shellcheck script.sh
shellcheck -x script.sh           # Follow source commands
shellcheck --shell=bash script.sh

# Common warnings ShellCheck catches:
# SC2086: Double quote to prevent globbing/word splitting
# SC2002: Useless cat
# SC2046: Quote this to prevent word splitting
# SC2181: Use 'if cmd' instead of 'if [ $? -eq 0 ]'
```

### Shell Injection Prevention

```bash
# DANGEROUS — never do this:
eval "ls $user_input"           # Arbitrary command execution
eval "$(echo $user_input)"      # Same

# SAFE patterns:

# 1. Quote everything
rm -rf "$directory"             # Safe even if $directory has spaces

# 2. Whitelist validation
case "$action" in
  start|stop|restart) systemctl "$action" "$service" ;;
  *) echo "Invalid action" >&2; exit 1 ;;
esac

# 3. Use arrays for argument lists — avoids word splitting
args=()
args+=(-c)
args+=("$host")
ping "${args[@]}"

# 4. Never eval user input — ever
# Instead: use a case/pattern match, function dispatch, or associative array
```

### Safer Script Patterns

```bash
#!/bin/bash
set -Eeuo pipefail

# PATH safety — use full paths or set known PATH
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Temporary files — use mktemp
tempfile=$(mktemp /tmp/script_XXXXXX)
trap 'rm -f "$tempfile"' EXIT

# Temporary directory
tempdir=$(mktemp -d /tmp/script_XXXXXX)
trap 'rm -rf "$tempdir"' EXIT

# Read secrets from file, not command line
read -s -p "Password: " db_pass

# Avoid parsing ls output
# BAD: for f in $(ls *.txt)
# GOOD: for f in *.txt
```

### Testing with BATS (Bash Automated Testing System)

```bash
# Install BATS
sudo apt install bats           # Debian/Ubuntu
# or: git clone https://github.com/bats-core/bats-core.git

# test_helper.bats
setup() {
  TEST_DIR=$(mktemp -d)
}

teardown() {
  rm -rf "$TEST_DIR"
}

@test "is_root detects root" {
  # Mock: simulate non-root
  run id -u
  [ "$status" -eq 0 ]
}

@test "validate_file handles missing file" {
  run validate_file "/nonexistent"
  [ "$status" -eq 1 ]
}

@test "bulk_rename renames .txt to .bak" {
  touch "$TEST_DIR"/test.txt
  run ./bulk_rename.sh "$TEST_DIR"
  [ -f "$TEST_DIR"/test.bak ]
}

# Run: bats test_helper.bats
```

### shfmt — Bash Formatter

```bash
# Install
sudo apt install shfmt

# Format in place
shfmt -w script.sh

# Check style (diff only)
shfmt -d script.sh

# Indent width
shfmt -i 2 -w script.sh
```



[← Previous](22-section-7-process-substitution-and-debugging.md) | [↑ Index](index.md) | [Next →](24-level-4-practices.md)
