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



---

[← Previous](11-section-5-input-and-output.md) | [↑ Index](index.md) | [Next →](13-section-1-error-handling-writing.md)
