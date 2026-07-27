## 2. grep in Depth

`grep` prints lines matching a pattern. Essential for log analysis, config auditing, code search.

### 2.1 Flavors and Flags

```bash
grep         # BRE by default
grep -E      # ERE (extended)
grep -F      # Fixed strings (no regex) — fastest
grep -P      # PCRE (if compiled in) — most powerful
grep -G      # BRE explicitly
```

### 2.2 Output Control

```bash
-o         # print only matching text, not whole line
-n         # print line numbers
-c         # count matches (per file)
-l         # list filenames with matches
-L         # list filenames WITHOUT matches
-q         # quiet (exit code only)
-m N       # stop after N matches per file
-H         # print filename (default with multiple files)
-h         # suppress filename
```

```bash
# Extract all IPs from log
grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' access.log

# Count errors per file
grep -c 'ERROR' *.log

# Just filenames with 500 errors
grep -l '" 500 ' access.log-*

# Stop after 5 matches
grep -m 5 'panic' dmesg
```

### 2.3 Context Control

```bash
-A N       # N lines After match
-B N       # N lines Before match
-C N       # N lines Context (both sides)
```

```bash
# Show 3 lines after each stack trace
grep -A 3 'Traceback' application.log

# Show 2 lines before each "denied"
grep -B 2 'denied' /var/log/auth.log

# Show 1 line around each error
grep -C 1 'CRITICAL' syslog
```

### 2.4 Recursive and File Filtering

```bash
-r / -R     # recursive
--include   # only matching files
--exclude   # skip matching files
--exclude-dir # skip directories
```

```bash
# Search all Python files for "requests"
grep -r --include='*.py' 'requests' /usr/lib/

# Skip node_modules
grep -r --exclude-dir=node_modules 'TODO' .

# Multiple includes
grep -r --include='*.{conf,cfg,ini}' 'port' /etc/
```

### 2.5 Advanced grep Patterns

```bash
# Find lines with duplicate words
grep -P '(?i)\b(\w+)\s+\1\b' text.txt

# Find lines between START and END markers
grep -Pz '(?s)START.*?END' multiline.txt

# Log levels: match whole words
grep -w 'ERROR\|FATAL\|PANIC' app.log

# IPv6 addresses
grep -P '([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}' /etc/hosts

# Email addresses
grep -oE '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' mail.log
```

### 2.6 grep Performance Notes

```bash
# 1. Use -F for literal strings (20-40x faster)
grep -F 'error' huge.log

# 2. Use -f for many patterns from a file
grep -f patterns.txt data.txt

# 3. Use LC_ALL=C for ASCII data
LC_ALL=C grep 'error' huge.log

# 4. Use -m to stop early
grep -m 10 'pattern' huge.log

# 5. Use parallel grep (xargs)
find . -name '*.log' | xargs -P4 grep 'ERROR'
```

---



---

[← Previous](04-1-regular-expressions-bre-vs.md) | [↑ Index](index.md) | [Next →](06-level-2-intermediary-tools-scripts.md)
