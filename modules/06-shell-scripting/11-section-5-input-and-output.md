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





[← Previous](10-section-4-arrays-multiple-values.md) | [↑ Index](index.md) | [Next →](12-level-2-practices.md)
