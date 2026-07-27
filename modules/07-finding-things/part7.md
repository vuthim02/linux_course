# 🐧 Linux System Administrator — Complete Course
## Part 7 of ∞: Finding Things — grep, find, locate, and Beyond

---

> **Reverse Engineering Approach:** A sysadmin's job is mostly hunting. Hunting for errors in logs, hunting for misconfigured files, hunting for processes that consume too much memory. The tools in this part are your tracking instincts turned into commands. We will start with the question "Where is the problem?" and work backward through the tools that answer it.

---

## 🎯 What You Will Achieve in Part 7

By the end of this part, you will:

- Search file contents with `grep` using patterns and regular expressions
- Use `find` to locate files by name, type, size, time, and permissions
- Use `locate` for instant filename lookups
- Master regular expressions — the universal pattern language
- Combine search tools with pipes for powerful investigations
- Search efficiently in log files during incidents
- Complete **18 hands-on practices**

---

## 🔍 Section 1: grep — Search File Contents

`grep` (Global Regular Expression Print) is the most used sysadmin command after `ls` and `cd`. It searches for patterns inside files.

### Basic Syntax

```bash
grep [options] pattern [file...]
```

### Simplest Use

```bash
# Search for "error" in a file
grep "error" /var/log/syslog

# Search multiple files
grep "error" /var/log/syslog /var/log/auth.log

# Search all files in a directory
grep "error" /var/log/*.log

# Recursive search through directories
grep -r "error" /var/log/

# Case-insensitive search
grep -i "error" /var/log/syslog
```

### Essential grep Options

```bash
-i      Case-insensitive search
-r      Recursive (search directories)
-n      Show line numbers
-c      Count matches (not content)
-v      Invert match (show NON-matching lines)
-l      Show only filenames with matches
-L      Show only filenames WITHOUT matches
-w      Match whole words only
-x      Match whole lines only
-q      Quiet (no output, use exit code only)
-o      Show only the matching part (not full line)
-E      Extended regex (same as egrep)
-H      Always show filename
-h      Never show filename
--color=auto   Highlight matches (usually default)
```

### Real Examples

```bash
# Count errors in a log file
grep -c "ERROR" /var/log/syslog

# Show line numbers of errors
grep -n "ERROR" /var/log/syslog

# Find which config files mention a specific setting
grep -rl "Port 22" /etc/ 2>/dev/null

# Find files that do NOT contain a pattern
grep -rL "enabled" /etc/nginx/

# Show context around matches
grep -B 5 "ERROR" app.log      # 5 lines Before
grep -A 5 "ERROR" app.log      # 5 lines After
grep -C 5 "ERROR" app.log      # 5 lines Context (both sides)

# Count occurrences per file
grep -rc "error" /var/log/*.log

# Find IP addresses in a file
grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" access.log | sort -u
```

### grep Exit Codes

```bash
grep -q "pattern" file
echo $?
# 0 = pattern found
# 1 = pattern not found
# 2 = error (file not found, etc.)
```

Use in scripts:

```bash
if grep -q "ERROR" /var/log/syslog; then
    echo "Errors found!"
    mail -s "Errors detected" admin@example.com < /var/log/syslog
fi
```

---

## 🔍 Section 2: Regular Expressions — The Pattern Language

A regular expression (regex) is a pattern language for matching text. `grep` with regex is exponentially more powerful than plain string search.

### Literal Characters

```bash
grep "error" file.txt    # Matches the exact string "error"
grep "127.0.0.1" file   # Matches the exact IP
```

### Character Classes

| Pattern | Matches |
|---------|---------|
| `.` | Any single character (except newline) |
| `[abc]` | One of a, b, or c |
| `[a-z]` | Any lowercase letter |
| `[0-9]` | Any digit |
| `[^abc]` | NOT a, b, or c |
| `[[:digit:]]` | Any digit (POSIX class) |
| `[[:alpha:]]` | Any letter |
| `[[:space:]]` | Whitespace (space, tab, newline) |
| `[[:upper:]]` | Uppercase letter |
| `[[:lower:]]` | Lowercase letter |

```bash
# Find lines with a 4-digit number
grep "[0-9][0-9][0-9][0-9]" file.txt

# Using POSIX class (same thing)
grep "[[:digit:]]\{4\}" file.txt

# Find lines starting with a capital letter
grep "^[A-Z]" file.txt
```

### Anchors

| Pattern | Matches |
|---------|---------|
| `^` | Beginning of line |
| `$` | End of line |
| `\b` | Word boundary |
| `\B` | NOT a word boundary |

```bash
# Lines starting with "ERROR"
grep "^ERROR" log.txt

# Lines ending with "success"
grep "success$" log.txt

# Whole word "port" (not "portable" or "transport")
grep "\bport\b" config.txt
```

### Quantifiers

| Pattern | Meaning |
|---------|---------|
| `*` | Zero or more of preceding character |
| `+` | One or more (needs `-E`) |
| `?` | Zero or one (needs `-E`) |
| `{n}` | Exactly n times |
| `{n,}` | n or more times |
| `{n,m}` | Between n and m times |

```bash
# Basic grep (no -E): escape { }
grep "[0-9]\{3\}" file.txt       # Exactly 3 digits

# Extended grep (-E): don't escape
grep -E "[0-9]{3}" file.txt       # Exactly 3 digits
grep -E "[0-9]{3,5}" file.txt     # 3 to 5 digits
grep -E "colou?r" file.txt        # color OR colour
grep -E "[a-z]+" file.txt         # One or more lowercase letters
```

### Alternation and Grouping

```bash
# Match "error" OR "warning" OR "fail"
grep -E "error|warning|fail" log.txt

# Match exact phrases
grep -E "(out of memory|disk full|cannot connect)" log.txt

# Repeated patterns
grep -E "(ab)+" file.txt          # ab, abab, ababab, ...
```

### The Most Common Regex Patterns for SysAdmins

```bash
# IPv4 address
grep -E "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" file

# Email address
grep -E "\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b" file

# URL
grep -E "https?://[^\s/$.?#].[^\s]*" file

# MAC address
grep -E "([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}" file

# Date in YYYY-MM-DD format
grep -E "\b[0-9]{4}-[0-9]{2}-[0-9]{2}\b" file

# Lines with only whitespace or empty
grep -E "^\s*$" file

# Valid Linux username (starts with letter, alphanumeric)
grep -E "^[a-z_][a-z0-9_-]*$" file
```

---

## 🔍 Section 3: grep in Practice — Log Investigation Workflow

When something breaks, this is how a sysadmin uses grep to investigate:

### Step 1: Check for Errors

```bash
# Quick check: any errors since last boot?
journalctl -p err -b | grep -i "fail\|error\|critical"
```

### Step 2: Find the Time Window

```bash
# Find when errors started
grep -n "ERROR" /var/log/app.log | head -5
# Shows line numbers — find the first error line
```

### Step 3: Get Context

```bash
# Show 10 lines before and after the first error
grep -n "ERROR" /var/log/app.log | head -1 | cut -d: -f1
# Then check that line in context
LINE=245
sed -n "$((LINE-10)),$((LINE+10))p" /var/log/app.log
```

### Step 4: Find Related Events

```bash
# Search for a specific session/request ID near the error
grep "SessionID: abc123" /var/log/app.log
```

### Step 5: Aggregated Report

```bash
# What types of errors occur most frequently?
grep -oE "\[ERROR\] [a-zA-Z ]+" log.txt | sort | uniq -c | sort -rn
```

---

## 🔍 Section 4: find — Advanced File Searching

`find` searches for files by **any attribute** — name, type, size, time, owner, permissions. It is more powerful than any GUI search tool.

### Basic Syntax

```bash
find [where_to_start] [conditions] [what_to_do]
```

### Find by Name

```bash
# Find by exact name
find /etc -name "hosts"

# Wildcard — all .conf files
find /etc -name "*.conf"

# Case-insensitive
find /etc -iname "*.CONF"

# Match multiple patterns
find /etc -name "*.conf" -o -name "*.cfg"
```

### Find by Type

```bash
find / -type f        # Regular files only
find / -type d        # Directories only
find / -type l        # Symbolic links
find / -type s        # Sockets
find / -type b        # Block devices (disks)
find / -type c        # Character devices (terminals)
find / -type p        # Named pipes (FIFOs)
```

### Find by Size

```bash
find / -size +100M    # Larger than 100 MB
find / -size -1k      # Smaller than 1 KB
find / -size 1024k    # Exactly 1024 KB (1 MB)
find / -size +500M -size -1G   # Between 500 MB and 1 GB
find / -empty         # Empty files and directories
```

### Find by Time

```bash
# Modification time
find /etc -mtime -7   # Modified in last 7 days
find /etc -mtime +30  # Modified more than 30 days ago
find /etc -mmin -60   # Modified in last 60 minutes

# Access time (last read)
find /home -atime -1   # Accessed in last 24 hours

# Change time (permission/ownership changed)
find /etc -ctime -1    # Changed in last 24 hours

# Newer than another file
find . -newer /etc/hosts   # Files newer than /etc/hosts
```

### Find by Owner and Permissions

```bash
# By user
find /home -user alice

# By group
find / -group developers

# By permission
find / -perm 644               # Exact permissions
find / -perm -4000             # SUID set (any of these bits)
find / -perm /4000             # ANY of these bits set
find / ! -perm 755             # NOT 755

# World-writable files (security risk)
find / -type f -perm -o+w

# No permissions for anyone
find / -perm 000
```

### Actions — What to Do With Results

```bash
# Default: print (same as -print)
find . -name "*.txt"

# Print with details (like ls -l)
find . -name "*.txt" -ls

# Delete
find /tmp -mtime +7 -delete

# Run a command on each result
find /var/log -name "*.log" -exec gzip {} \;
# {} = placeholder for each file
# \; = end of exec command

# Run a command with + (batch, more efficient)
find /var/log -name "*.log" -exec chmod 640 {} +
# + = put all files at the end of one command

# Run with custom command
find . -name "*.jpg" -exec convert {} -resize 800x600 {} \;
```

### find vs ls — Why find Is Necessary

```bash
# What if you want files modified in the last 7 days?
# ls cannot do this with a single command.
# ls -lt shows sorted by time, but not time range.

# find does it easily:
find /etc -mtime -7

# What if you want files larger than 100MB?
# ls -laS shows sorted by size, but not size threshold.

# find:
find / -size +100M
```

### Combining find With Other Commands

```bash
# Find and count
find /etc -type f | wc -l

# Find and copy
find /var/log -name "*.log" -mtime -1 -exec cp {} /backup/ \;

# Find and tar
find /home -name "*.doc" -type f | tar -czf docs_backup.tar.gz -T -

# Find and show disk usage
find /var/log -name "*.log" -size +10M -exec du -h {} \;
```

### Safety With find -exec

```bash
# DANGEROUS — always test first!
find / -name "important*" -delete
# ^ This could delete everything named "important*"

# SAFE approach:
find / -name "important*"          # Step 1: Preview results
find / -name "important*" -ls      # Step 2: See details
find / -name "important*" -delete  # Step 3: Only if step 1-2 look right
```

### find and xargs

`xargs` reads items from stdin and executes a command with them. It is more efficient than `-exec` for large result sets.

```bash
# Find and delete (xargs is faster than -exec for many files)
find /tmp -mtime +30 -type f -print | xargs rm

# Find and chmod
find . -type f -name "*.sh" -print | xargs chmod +x

# Find and grep contents
find /etc -name "*.conf" -print | xargs grep "Port" 2>/dev/null

# With null separator (handles spaces in filenames)
find . -name "*.txt" -print0 | xargs -0 rm
```

---

## 🔍 Section 5: locate — Instant Filename Search

`locate` searches a pre-built database of filenames. It is **instant** but does not search file contents.

```bash
# Find any file named "hosts"
locate hosts

# Case-insensitive
locate -i "Hosts"

# Count matches
locate -c "*.conf"

# Show only existing files (database may be outdated)
locate -e "hosts"

# Limit results
locate "*.conf" | head -20
```

### Updating the locate Database

```bash
# The database is updated daily by cron
# But you can force an update:
sudo updatedb

# Check when the database was last updated
ls -l /var/lib/mlocate/mlocate.db
```

### locate vs find

| Aspect | find | locate |
|--------|------|--------|
| Speed | Slow (scans disk live) | Instant (database lookup) |
| Accuracy | Always current | May be outdated |
| Content search | No (only filenames) | No (only filenames) |
| Search criteria | Name, size, time, type, perms | Name only |
| Disk I/O | Heavy | None |

> 💡 Use `locate` for quick "where is that file?" questions. Use `find` when you need current data, complex criteria, or actions.

---

## 🔍 Section 6: Modern Alternatives — rg, ag, ack

### ripgrep (rg) — The Fastest

```bash
# Install
sudo apt install ripgrep        # Debian/Ubuntu
sudo dnf install ripgrep         # Fedora
```

```bash
# Default search (recursive, respects .gitignore)
rg "pattern"

# Show line numbers
rg -n "pattern"

# Case-insensitive
rg -i "pattern"

# Show context
rg -C 5 "pattern"

# Search only .log files
rg -g "*.log" "error"

# Search but exclude a pattern
rg -g "*.log" "error" --glob '!access.log'
```

### Why ripgrep Is Better Than grep for Large Codebases

```bash
# ripgrep is 5-10x faster on large directories
# It automatically ignores:
#   - .gitignore patterns
#   - Hidden files (unless you use -.)
#   - Binary files
#   - Symlinks (unless -L)

# Compare:
time grep -r "pattern" /usr/src   # Slow
time rg "pattern" /usr/src        # Fast
```

### silver searcher (ag) and ack

```bash
# ag — similar to rg, very fast
ag "pattern"

# ack — Perl-compatible regex, developer-focused
ack "pattern"
```

---

## 🔍 Section 7: Looking at Files — Quick Preview Commands

### file — Identify File Type

```bash
file /bin/ls              # ELF binary
file /etc/hosts           # ASCII text
file image.jpg            # JPEG image data
file unknown_file         # Determines what it is
file -i document.pdf      # MIME type: application/pdf
```

### stat — Detailed File Information

```bash
stat /etc/hosts
# File: /etc/hosts
# Size: 221      Blocks: 8     IO Block: 4096  regular file
# Device: 801h/2049d  Inode: 1234567  Links: 2
# Access: 2024-01-15 10:30:00.000000000 -0500
# Modify: 2024-01-15 10:30:00.000000000 -0500
# Change: 2024-01-15 10:30:00.000000000 -0500
# Birth: 2023-12-01 14:22:00.000000000 -0500
```

### du — Disk Usage by File/Directory

```bash
du -sh /var/log            # Total size of directory
du -sh * | sort -rh        # Sizes of all items, sorted
du -sh /* 2>/dev/null | sort -rh | head -10  # Largest root dirs
```

### type — Where Does a Command Come From

```bash
type ls           # ls is /usr/bin/ls
type cd           # cd is a shell builtin
type -a ls        # All locations (including aliases)
```

### which — Find Executable Path

```bash
which python3     # /usr/bin/python3
which -a ssh      # All ssh binaries in PATH
```

---

## 💻 PRACTICE SECTION — 18 Hands-On Exercises

---

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

---

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

---

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

---

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

---

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

---

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

---

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

---

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

---

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

---

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

---

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

---

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

---

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

---

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

---

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

---

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

---

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

---

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

---

## 🧠 Deep Understanding — How Search Tools Work

### grep Internals

When you run `grep "pattern" file.txt`:

```
1. grep opens file.txt
2. Reads one line at a time into memory
3. Compiles the regex pattern into an internal state machine
4. For each line: runs the state machine against the characters
5. If match found: prints the line
6. Continues until EOF

Why grep is fast: it processes lines sequentially (no random access),
and the Boyer-Moore algorithm skips ahead when possible.
```

### The Locate Database

```
updatedb reads the entire filesystem tree and stores:
  - File paths
  - Permissions (for security — root files are hidden from normal users)
  
Database location: /var/lib/mlocate/mlocate.db
Update schedule: daily via /etc/cron.daily/mlocate

Why locate is instant: it searches a sorted database using binary search (O(log n))
```

### The find Algorithm

```
find traverses the directory tree using readdir() for each directory.
For each entry, it applies your test conditions in order.
If all conditions pass, it performs the action.

Performance tip: put the cheapest tests first
  - Type check (-type f) is very fast
  - Size check (-size) requires stat() call (slower)
  - Content check (-exec grep) requires opening file (slowest)

So: find . -type f -name "*.log" -size +10M
Better than: find . -size +10M -name "*.log" -type f
```

### Why grep -r Can Be Slow (and How to Fix It)

```
grep -r opens EVERY file, including binary files.
Speed tips:
  grep -r --include="*.log" "pattern"   # Only .log files
  grep -r --exclude="*.bin" "pattern"   # Skip binaries
  rg "pattern"                           # ripgrep is smarter
```

---

## 📋 Summary — Complete Command Reference for Part 7

### grep

| Command | Action |
|---------|--------|
| `grep pattern file` | Search for pattern in file |
| `grep -i pattern file` | Case-insensitive search |
| `grep -r pattern dir` | Recursive search |
| `grep -n pattern file` | Show line numbers |
| `grep -c pattern file` | Count matches |
| `grep -v pattern file` | Invert match (non-matching lines) |
| `grep -l pattern dir/*` | Show only filenames with matches |
| `grep -o pattern file` | Show only matching text |
| `grep -C 3 pattern file` | Show 3 lines context |
| `grep -E pattern file` | Extended regex |
| `grep -q pattern file` | Quiet (exit code only) |

### Regular Expressions

| Pattern | Matches |
|---------|---------|
| `.` | Any single character |
| `^` | Start of line |
| `$` | End of line |
| `*` | Zero or more |
| `+` | One or more |
| `?` | Zero or one |
| `{n,m}` | Between n and m times |
| `[abc]` | Any of a, b, c |
| `[^abc]` | NOT a, b, c |
| `(a\|b)` | a or b |
| `\b` | Word boundary |
| `\d` | Digit (in some regex engines) |

### find

| Command | Action |
|---------|--------|
| `find . -name "*.txt"` | Find by name |
| `find . -type f` | Regular files only |
| `find . -type d` | Directories only |
| `find / -size +100M` | Files larger than 100 MB |
| `find / -mtime -7` | Modified in last 7 days |
| `find / -mmin -60` | Modified in last 60 minutes |
| `find / -user alice` | Owned by alice |
| `find / -perm 644` | Exact permissions |
| `find / -perm -4000` | SUID set |
| `find . -empty` | Empty files/dirs |
| `find . -exec cmd {} \;` | Run command on each result |
| `find . -delete` | Delete found files |

### locate

| Command | Action |
|---------|--------|
| `locate name` | Find file by name instantly |
| `locate -i name` | Case-insensitive |
| `locate -c pattern` | Count matches |
| `locate -e name` | Only existing files |
| `sudo updatedb` | Update database |

### Other

| Command | Action |
|---------|--------|
| `file path` | Identify file type |
| `stat path` | Detailed file info |
| `du -sh dir` | Disk usage summary |
| `type command` | How shell interprets command |
| `which command` | Path of executable |
| `rg pattern` | ripgrep (fast, modern) |

---

## 🚀 What's Coming in Part 8

**Part 8: Archiving and Compression — tar, gzip, zip**

You will learn:
- Creating and extracting tar archives
- gzip, bzip2, xz — compression algorithms compared
- Combining tar with compression in one step
- Creating and extracting zip files
- Backing up directories with proper options
- 15 hands-on practices

---

## 📝 Self-Test — Can You Answer These?

1. How do you search for "error" case-insensitively in a file?
2. What does `grep -c "error" file.log` do?
3. What is the difference between `*` and `+` in regular expressions?
4. How do you search for lines that start with "ERROR"?
5. How do you show 5 lines of context before and after a match?
6. How do you find all files larger than 100MB?
7. How do you find files modified in the last 7 days?
8. What does `find . -name "*.tmp" -delete` do?
9. What is the difference between `find` and `locate`?
10. How do you update the locate database?
11. When would you use `rg` instead of `grep`?
12. What does `find . -type f -perm -4000` find?
13. How do you find all empty files in a directory?
14. Write a command to find all `.conf` files containing the word "Port".
15. How do you count unique IP addresses in a log file?

**Score:** 12/15 correct = ready for Part 8.

---

*Linux SysAdmin Course | Part 7 of ∞ | Reverse Engineering Approach*
*Previous → Part 6: Shell Scripting — Automate Everything*
*Next → Part 8: Archiving and Compression — tar, gzip, zip*

[← Previous](part6.md) | [Next →](part8.md)
