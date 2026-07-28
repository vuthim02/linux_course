## 💻 PRACTICE SECTION — 18 Hands-On Exercises


### ✅ Practice 1: Basic grep

```bash
mkdir -p ~/linux-course/part7
cd ~/linux-course/part7

# Create a sample log file
cat > app.log << 'EOF'
2024-01-15 10:00:01 INFO Application started
2024-01-15 10:01:05 INFO Connected to database
2024-01-15 10:02:33 WARNING High memory usage detected
2024-01-15 10:03:00 ERROR Failed to write to disk
2024-01-15 10:04:12 INFO Reconnecting to database
2024-01-15 10:05:00 ERROR Connection timeout after 30 seconds
2024-01-15 10:06:22 CRITICAL Database connection lost
2024-01-15 10:07:00 INFO Restarting service
2024-01-15 10:08:15 INFO Service started successfully
EOF

# Search for ERROR
grep "ERROR" app.log

# Count errors
grep -c "ERROR" app.log

# Show line numbers
grep -n "ERROR" app.log
```


### ✅ Practice 2: grep Options

```bash
cd ~/linux-course/part7

# Case-insensitive
grep -i "info" app.log

# Invert match (show non-error lines)
grep -v "ERROR\|CRITICAL" app.log

# Show only matching parts
grep -oE "[0-9]{2}:[0-9]{2}:[0-9]{2}" app.log

# Context (before and after)
grep -C 2 "CRITICAL" app.log

# Count per severity
echo "INFO: $(grep -c 'INFO' app.log)"
echo "WARNING: $(grep -c 'WARNING' app.log)"
echo "ERROR: $(grep -c 'ERROR' app.log)"
echo "CRITICAL: $(grep -c 'CRITICAL' app.log)"
```


### ✅ Practice 3: Recursive grep

```bash
cd ~/linux-course/part7

# Create some config files
mkdir -p configs
echo "port=8080" > configs/app.conf
echo "host=localhost" > configs/database.conf
echo "debug=true" > configs/debug.conf
echo "port=5432" > configs/db_port.conf

# Search recursively
grep -r "port" configs/

# Show only filenames
grep -rl "port" configs/

# Count per file
grep -rc "port" configs/
```


### ✅ Practice 4: Regular Expressions — Basics

```bash
cd ~/linux-course/part7

# Match lines containing a number
grep -E "[0-9]" app.log

# Match lines starting with 2024
grep "^2024" app.log

# Match lines ending with "started"
grep "started$" app.log

# Match INFO or WARNING
grep -E "INFO|WARNING" app.log

# Match any word that starts with "C"
grep -oE "\bC\w+" app.log
```


### ✅ Practice 5: Regex — IP Addresses

```bash
cd ~/linux-course/part7

# Create a file with IP addresses
cat > ips.txt << 'EOF'
Server 192.168.1.100 is online
192.168.1.101 - Failed connection
Connected from 10.0.0.5
Invalid: 999.999.999.999
DNS: 8.8.8.8
Local: 127.0.0.1
EOF

# Extract all IP addresses
grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" ips.txt

# Unique IPs only
grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" ips.txt | sort -u
```


### ✅ Practice 6: Regex — Emails and URLs

```bash
cd ~/linux-course/part7

# Create a mixed data file
cat > data.txt << 'EOF'
Contact: admin@example.com
Support: support@company.org
Web: https://www.example.com
Internal: http://intranet.local/info
User: alice@university.edu
EOF

# Extract emails
grep -oE "\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b" data.txt

# Extract URLs
grep -oE "https?://[^\s]+" data.txt
```


### ✅ Practice 7: find by Name

```bash
mkdir -p ~/linux-course/part7/find_test
cd ~/linux-course/part7/find_test

# Create a test structure
mkdir -p project/{src,tests,docs}
touch project/src/main.py project/src/utils.py
touch project/tests/test_main.py project/tests/test_utils.py
touch project/docs/README.md project/docs/notes.txt
touch project/.hidden_file

# Find by name
find . -name "*.py"

# Case-insensitive
find . -iname "*.PY"

# Multiple patterns
find . -name "*.md" -o -name "*.txt"

# Not matching
find . -not -name "*.py"
```


### ✅ Practice 8: find by Type and Size

```bash
cd ~/linux-course/part7/find_test

# Create files of different sizes
dd if=/dev/urandom of=small.bin bs=1k count=1 2>/dev/null
dd if=/dev/urandom of=medium.bin bs=1M count=1 2>/dev/null
dd if=/dev/urandom of=large.bin bs=10M count=1 2>/dev/null

# Find by type
find . -type f
find . -type d

# Find by size
find . -size +1M -type f
find . -size -10k -type f
find . -size +1M -size -20M -type f

# Empty files
touch empty.txt
find . -empty -type f
```


### ✅ Practice 9: find by Time

```bash
cd ~/linux-course/part7

# Find files modified in last 5 minutes
find find_test/ -mmin -5 -type f

# Create a file with old timestamp
touch -t 202301010000 find_test/old_file.txt

# Find files older than 1 year
find find_test/ -mtime +365 -type f

# Find recently changed files
find /etc -mtime -1 -type f 2>/dev/null
```


### ✅ Practice 10: find by Permission

```bash
cd ~/linux-course/part7/find_test

# Make some files executable
chmod +x project/src/*.py
chmod 777 project/docs/notes.txt

# Find executable files
find . -executable -type f

# Find world-writable files (security issue)
find . -perm -o+w -type f

# Find SUID files
find /usr/bin -perm -4000 -type f 2>/dev/null

# Find files with exactly 644
find . -perm 644 -type f
```


### ✅ Practice 11: find -exec

```bash
cd ~/linux-course/part7/find_test

# Find and show details
find . -name "*.py" -ls

# Find and count lines
find . -name "*.py" -exec wc -l {} \;

# Find and change permissions
find . -name "*.txt" -exec chmod 644 {} \;

# Find and compress
find . -name "*.bin" -exec gzip {} \;
ls -la
```


### ✅ Practice 12: find with xargs

```bash
cd ~/linux-course/part7/find_test

# Create more test files
touch file{1..20}.txt

# Find and delete with xargs
find . -name "file*.txt" -print | xargs rm

# Find and grep content
find . -type f -name "*.py" -print | xargs grep -l "main" 2>/dev/null
```


### ✅ Practice 13: locate

```bash
# Update the database first (may need sudo)
sudo updatedb 2>/dev/null || echo "locate may not be installed"

# Find files named "hosts"
locate hosts

# Find all .conf files (limited)
locate "*.conf" | head -10

# Count .conf files
echo "Total .conf files: $(locate -c '*.conf')"

# Case-insensitive
locate -i "Readme"
```


### ✅ Practice 14: grep in Logs

```bash
# Check system log for errors
journalctl -p err -b --no-pager 2>/dev/null | head -20

# Check authentication failures
sudo grep "Failed password" /var/log/auth.log 2>/dev/null || \
echo "auth.log may not exist (check /var/log/secure)"

# Count failed logins
sudo grep -c "Failed password" /var/log/auth.log 2>/dev/null

# Unique IPs that failed login
sudo grep "Failed password" /var/log/auth.log 2>/dev/null | \
grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | sort -u
```


### ✅ Practice 15: Real SysAdmin — Find Large Files

```bash
cd ~/linux-course/part7

# Find the 10 largest files on the system (from /var)
find /var -type f -size +10M 2>/dev/null -exec ls -lh {} \; 2>/dev/null | \
sort -k5 -rh | head -10

# Find the 10 largest directories in /home
du -sh /home/* 2>/dev/null | sort -rh | head -10

# Find files accessed in the last day
find /home -type f -atime -1 2>/dev/null | head -20
```


### ✅ Practice 16: Real SysAdmin — Find SUID and Security Issues

```bash
cd ~/linux-course/part7

# All SUID files
find / -type f -perm -4000 2>/dev/null | tee suid_files.txt
echo "SUID files found: $(wc -l < suid_files.txt)"

# World-writable files in /etc
find /etc -type f -perm -o+w 2>/dev/null
echo "World-writable files in /etc found."

# Files owned by nobody
find / -user nobody -type f 2>/dev/null | head -10
```


### ✅ Practice 17: Real SysAdmin — Log Analysis Pipeline

```bash
cd ~/linux-course/part7

# Build a complete log analysis pipeline
# Find the most common error messages in /var/log
# (adjust for your system)
journalctl -p err -b --no-pager 2>/dev/null | \
grep -oE "\b[a-zA-Z]{3,}\b" | \
sort | uniq -c | sort -rn | head -20

# Alternative: look at syslog
if [ -f /var/log/syslog ]; then
    grep -oE "\[?ERROR\]?|\[?FAILED\]?|\[?CRITICAL\]?" /var/log/syslog | \
    sort | uniq -c | sort -rn
fi
```


### ✅ Practice 18: Real SysAdmin — Find and Archive Old Logs

```bash
cd ~/linux-course/part7

# Create a practice cleanup script
cat > archive_old_logs.sh << 'EOF'
#!/bin/bash
set -euo pipefail

LOG_DIR="${1:-/var/log}"
DAYS_OLD="${2:-30}"
ARCHIVE_DIR="/var/log/archive"

echo "Finding log files older than $DAYS_OLD days in $LOG_DIR..."
echo ""

# Find old log files
OLD_LOGS=$(find "$LOG_DIR" -name "*.log" -type f -mtime "+$DAYS_OLD")

if [ -z "$OLD_LOGS" ]; then
    echo "No log files older than $DAYS_OLD days found."
    exit 0
fi

echo "$OLD_LOGS" | while read -r logfile; do
    echo "  Found: $logfile ($(du -h "$logfile" | cut -f1))"
done

echo ""
echo "Total space: $(echo "$OLD_LOGS" | xargs du -ch 2>/dev/null | tail -1 | cut -f1)"

# Uncomment to actually archive:
# mkdir -p "$ARCHIVE_DIR"
# echo "$OLD_LOGS" | while read -r logfile; do
#     gzip "$logfile"
#     mv "${logfile}.gz" "$ARCHIVE_DIR/"
#     echo "Archived: $logfile"
# done
EOF

chmod +x archive_old_logs.sh
./archive_old_logs.sh /var/log 365
```





[← Previous](08-section-7-looking-at-files.md) | [↑ Index](index.md) | [Next →](10-deep-understanding-how-search-tools.md)
