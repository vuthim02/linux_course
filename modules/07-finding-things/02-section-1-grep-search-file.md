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





[← Previous](01-what-you-will-achieve-in.md) | [↑ Index](index.md) | [Next →](03-section-2-regular-expressions-the.md)
