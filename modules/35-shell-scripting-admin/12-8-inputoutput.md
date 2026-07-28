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





[← Previous](11-7-functions.md) | [↑ Index](index.md) | [Next →](13-9-error-handling.md)
