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





[← Previous](17-level-3-advanced-security-internals.md) | [↑ Index](index.md) | [Next →](19-15-deep-understanding.md)
