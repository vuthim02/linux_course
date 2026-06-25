# 🐧 Linux System Administrator — Complete Course
## Part 36 of ∞: Advanced Shell Scripting — sed, awk, regular expressions

---

*"Some people, when confronted with a problem, think 'I know, I'll use regular expressions.' Now they have two problems." — Jamie Zawinski*

*This joke is funny because it's true — but a sysadmin who masters regex, sed, and awk can solve in one line what takes others a hundred.*



## 🎯 What You Will Achieve

This module is structured across three progressive levels:

| Level | Focus | What You'll Learn |
|-------|-------|-------------------|
| ⭐ Level 1: Basic — Foundations | Regex & grep | BRE/ERE/PCRE flavors, grep in depth, anchors, quantifiers, character classes, lookahead/lookbehind |
| ⭐ Level 2: Intermediary — Tools & Scripts | sed, awk, Core Utilities & Real-World Scripts | Stream editing with sed, text processing with awk, cut, sort, uniq, wc, tr, paste, join, comm, xargs, diff/patch, admin patterns, real-world scripts |
| ⭐ Level 3: Advanced — Practices & Internals | Practice & Deep Understanding | Multi-line patterns, hold space, associative arrays, regex engine internals, NFA/DFA, performance optimization, comprehensive self-test |

---

## Table of Contents

1. Regular Expressions — BRE vs ERE vs PCRE
2. grep in Depth
3. sed — Stream Editor
4. sed Admin Patterns
5. awk — Text Processing Language
6. awk Admin Patterns
7. Combining Tools
8. cut, sort, uniq, wc, tr
9. paste, join, comm
10. xargs
11. diff and patch
12. Real-World Admin Scripts
13. Hands-On Practices (15)
14. Deep Understanding
15. Command Reference
16. Self-Test

---

## ⭐ Level 1: Basic — Foundations

![Regular expression visualization](https://upload.wikimedia.org/wikipedia/commons/2/2e/Regular_expression.svg)

> *"The power of the command line lies in pattern matching. Master regex, and you master text."*

---

## 1. Regular Expressions — BRE vs ERE vs PCRE

A regular expression (regex) is a pattern that describes a set of strings. Every sysadmin must understand three flavors.

### 1.1 BRE (Basic Regular Expressions)

The original Unix regex. Meta-characters `?`, `+`, `{`, `|`, `(`, `)` lose their special meaning unless escaped with `\`.

| Pattern | Meaning in BRE |
|---------|---------------|
| `abc`   | literal string |
| `a\.b`  | a, dot, b (dot escaped) |
| `^`     | start of line |
| `$`     | end of line |
| `.*`    | zero or more of any char |
| `[abc]` | one of a, b, c |
| `[^abc]`| NOT a, b, c |
| `\(abc\)` | grouping (escaped parens) |
| `abc\|def` | alternation (escaped pipe) |
| `a\{3\}` | exactly 3 a's (escaped braces) |

```bash
# BRE default in grep (no -E)
grep '^root:' /etc/passwd
grep '\(foo\|bar\)' file.txt
```

### 1.2 ERE (Extended Regular Expressions)

Meta-characters are special **without** escaping. Used by `grep -E`, `awk`, `sed -E`.

| Pattern | Meaning in ERE |
|---------|---------------|
| `a?`    | zero or one a |
| `a+`    | one or more a |
| `a{3}`  | exactly 3 a's |
| `(abc)` | grouping |
| `abc\|def` | alternation |

```bash
grep -E '^[A-Za-z_][A-Za-z0-9_]*$' identifiers.txt
```

### 1.3 PCRE (Perl-Compatible Regular Expressions)

Richest flavor: lookahead, lookbehind, non-capturing groups, backreferences. Used by `grep -P`, `pcregrep`, `perl`, `python`.

```bash
grep -P '(?<=\$)[A-Z_]+(?=\s* =)' script.sh  # variable names after $
```

### 1.4 Anchors

```bash
^         # start of line
$         # end of line
\b        # word boundary (PCRE/ERE in some tools)
\B        # non-word boundary
\A        # start of string (PCRE)
\Z        # end of string (PCRE)
```

```bash
grep '^#\|^$' config.conf      # comments + blank lines
grep -P '^.{0,80}$' file.txt   # lines ≤ 80 chars
```

### 1.5 Quantifiers

```bash
*       # 0 or more  (greedy)
\+ / +  # 1 or more  (escaped in BRE)
\? / ?  # 0 or 1
{n,m}   # n to m times
{n}     # exactly n
{n,}    # n or more
*?      # lazy 0 or more (PCRE)
+?      # lazy 1 or more (PCRE)
```

```bash
# IP address pattern (ERE)
grep -E '([0-9]{1,3}\.){3}[0-9]{1,3}' access.log

# Hex color
grep -P '#[0-9a-fA-F]{3}(?:[0-9a-fA-F]{3})?' style.css
```

### 1.6 Character Classes

```bash
[abc]         # a, b, or c
[^abc]        # NOT a, b, or c
[a-z]         # range a to z
[[:alpha:]]   # POSIX: alphabetic
[[:digit:]]   # POSIX: digit
[[:space:]]   # POSIX: whitespace
[[:upper:]]   # POSIX: uppercase
[[:lower:]]   # POSIX: lowercase
[[:alnum:]]   # POSIX: alphanumeric
[[:punct:]]   # POSIX: punctuation
[[:blank:]]   # POSIX: space or tab
```

```bash
# POSIX classes are locale-aware
grep '[[:digit:]]' file.txt     # digits in any locale
grep '[0-9]' file.txt           # ASCII digits only
grep '[[:upper:]]' names.txt    # works with accented chars
```

### 1.7 Grouping and Backreferences

```bash
# ERE
grep -E '(foo) \1' file.txt    # "foo foo"
sed -E 's/([a-z]+) \1/\1/g'    # remove duplicated words

# BRE requires escaped parens
sed 's/\([a-z]\)\([0-9]\)/\2\1/g'

# PCRE: non-capturing group
grep -P '(?:foo|bar)baz'

# PCRE: named groups (Python/Perl)
(?P<name>pattern) \k<name>
```

### 1.8 Lookahead and Lookbehind (PCRE)

```bash
(?=pattern)   # positive lookahead
(?!pattern)   # negative lookahead
(?<=pattern)  # positive lookbehind
(?<!pattern)  # negative lookbehind
```

```bash
# Extract values after "key="
grep -P '(?<=key=)\w+' config.txt

# Lines NOT followed by "END"
grep -P '^START(?!.*END)' file.txt

# Lines NOT preceded by "#"
grep -P '(?<!#)include' config.cfg

# Password-like strings (8+ chars, letter + digit)
grep -P '^(?=.*[a-zA-Z])(?=.*[0-9]).{8,}' passwords.txt
```

### 1.9 Regex Pitfalls

```bash
# Greediness
echo '<tag>text</tag>' | grep -Po '<.*>'    # matches whole line
echo '<tag>text</tag>' | grep -Po '<.*?>'   # matches <tag> only

# Catastrophic backtracking
# BAD:  (a|aa|aaa|aaaa)*b   — exponential with long strings
# GOOD: a+b                  — linear

# [0-9] vs [[:digit:]]
[0-9]     # ASCII 0-9 only
[[:digit:]] # locale-aware: digits in Arabic, Devanagari, etc.
```

---

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

## ⭐ Level 2: Intermediary — Tools & Scripts

![sed and awk](https://upload.wikimedia.org/wikipedia/commons/3/34/GNU_awk_3.1.6_expression.svg)

> *"sed transforms; awk analyzes. Together they are the sysadmin's scalpel and microscope."*

---

## 3. sed — Stream Editor

`sed` reads line by line, applies commands, outputs result. Non-interactive text transformation.

### 3.1 How sed Works (The Cycle)

```
Read a line → Execute commands → Print (unless -n) → Repeat
```

```bash
sed 's/old/new/' file.txt        # basic substitute
sed -n '5,10p' file.txt          # print lines 5-10
sed '3d' file.txt                # delete line 3
```

### 3.2 The s Command — Substitute

```
s/pattern/replacement/flags
```

| Flag | Meaning |
|------|---------|
| `g`  | global (all occurrences on line) |
| `N`  | replace Nth occurrence |
| `p`  | print line if substitution occurred |
| `w file` | write to file if substitution occurred |
| `i`  | case-insensitive |
| `e`  | execute replacement as command (GNU sed) |

```bash
sed 's/foo/bar/' file.txt          # first occurrence per line
sed 's/foo/bar/g' file.txt         # all occurrences
sed 's/foo/bar/2' file.txt         # only second occurrence
sed -n 's/ERROR/CRITICAL/p' log    # print changed lines only
sed 's/[0-9]/[&]/g' file.txt       # wrap each digit in brackets
sed 's/\(foo\)/\1bar/' file.txt    # backreference: foobar
```

### 3.3 Address Ranges

```bash
sed '3s/foo/bar/' file.txt         # line 3 only
sed '/pattern/s/foo/bar/' file.txt # lines matching pattern
sed '5,10s/foo/bar/' file.txt      # lines 5-10
sed '/start/,/end/s/foo/bar/'      # between markers
sed '5,$s/foo/bar/' file.txt       # line 5 to end
sed '1~3d' file.txt                # every 3rd line starting at 1
```

### 3.4 sed Commands

```bash
s       # substitute
d       # delete line
p       # print line (with -n)
a       # append text after line
i       # insert text before line
c       # change (replace) line
y       # transliterate (like tr)
q       # quit
r       # read file into output
w       # write line to file
=       # print line number
N       # read next line into pattern space
D       # delete up to first newline in pattern space
P       # print up to first newline in pattern space
h       # copy pattern space to hold space
H       # append pattern space to hold space
g       # copy hold space to pattern space
G       # append hold space to pattern space
x       # exchange pattern and hold spaces
```

```bash
# Delete blank lines
sed '/^$/d' file.txt

# Print line numbers
sed '=' file.txt | sed 'N;s/\n/\t/'

# Insert header before line 1
sed '1i\# Generated on '$(date)'' file.txt

# Append footer
sed '$a\# End of file' file.txt

# Change a line
sed '/^DEBUG/c\# DEBUG mode disabled' config.txt

# Transliterate (like tr)
sed 'y/abcdef/ABCDEF/' file.txt
```

### 3.5 The Hold Space

sed has two buffers:
- **Pattern space** — the working line
- **Hold space** — a storage buffer

```bash
# Reverse line order of file (tac equivalent)
sed '1!G;h;$!d' file.txt

# Print paragraph if it contains a pattern
sed -n '/pattern/{h;:a;n;/./{H;ba};g;p}' file.txt

# Duplicate each line
sed 'G' file.txt

# Join every other line
sed 'N;s/\n/ /' file.txt
```

### 3.6 Multi-line sed (N, D, P)

```bash
# Join lines ending with backslash
sed '/\\$/{N;s/\\\n//}' file.txt

# Print from START to END inclusive
sed -n '/START/,/END/p' file.txt

# Delete blank lines and surrounding
sed '/^$/{N;/^\n$/d}' file.txt

# Replace \n with comma between lines
sed ':a;N;$!ba;s/\n/,/g' file.txt
```

### 3.7 sed -i (In-Place Editing)

```bash
# GNU sed (Linux)
sed -i 's/old/new/g' file.txt
sed -i.bak 's/old/new/g' file.txt   # backup as file.txt.bak
sed -i '' 's/old/new/g' file.txt    # BSD sed (macOS)

# Multiple expressions with -e
sed -i -e 's/foo/bar/' -e 's/baz/qux/' file.txt

# Script file
sed -i -f commands.sed file.txt
```

---

## 4. sed Admin Patterns

### 4.1 Config File Editing

```bash
# Uncomment a line
sed -i 's/^#\s*Port\s\+22/Port 22/' /etc/ssh/sshd_config

# Change a value
sed -i 's/^MAX_CONNECTIONS=.*/MAX_CONNECTIONS=500/' .env

# Add line after a match
sed -i '/^\[mysqld\]/a\bind-address = 0.0.0.0' /etc/mysql/my.cnf

# Add line before a match
sed -i '/^server {/i\    listen 443 ssl;' /etc/nginx/sites-available/default

# Remove a line
sed -i '/^# insecure/d' /etc/nginx/nginx.conf

# Ensure a line exists (idempotent)
grep -q '^Color=always' config.ini || sed -i '$a\Color=always' config.ini
```

### 4.2 Log Anonymization

```bash
# Anonymize IPs (replace last octet with .0)
sed -E 's/([0-9]{1,3}\.){3}[0-9]{1,3}/\1**0/g' access.log

# Anonymize email addresses
sed -E 's/([a-zA-Z0-9._%+-]+)@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/\1@redacted.com/g'

# Anonymize credit cards (show last 4)
sed -E 's/[0-9]{4}-[0-9]{4}-[0-9]{4}-([0-9]{4})/****-****-****-\1/g'

# Remove sensitive headers
sed -i '/^Authorization:/d' request.log
```

### 4.3 File Templating

```bash
# Template substitution
sed -e "s/{{HOSTNAME}}/$(hostname)/g" \
    -e "s/{{DATE}}/$(date)/g" \
    -e "s/{{IP}}/$(hostname -I | awk '{print $1}')/g" \
    template.conf > output.conf

# With environment variables
sed "s/{{DB_HOST}}/${DB_HOST:-localhost}/g" template.cfg

# Heredoc with sed
bash -c "$(sed 's/{{USER}}/'"$USER"'/g' script.template)"
```

### 4.4 In-Place Changes in Scripts

```bash
#!/bin/bash
# safe_sed.sh — safe in-place editing

SED_SCRIPT="/etc/nginx/nginx.conf"
BACKUP="${SED_SCRIPT}.bak.$(date +%Y%m%d%H%M%S)"

cp "$SED_SCRIPT" "$BACKUP"
sed -i 's/worker_connections\s\+[0-9]\+/worker_connections 2048/' "$SED_SCRIPT"

if nginx -t; then
    systemctl reload nginx
    echo "Config applied. Backup at $BACKUP"
else
    cp "$BACKUP" "$SED_SCRIPT"
    echo "Config invalid! Restored backup."
    exit 1
fi
```

### 4.5 sed One-Liners

```bash
# Strip HTML tags
sed -e 's/<[^>]*>//g' file.html

# Remove trailing whitespace
sed -i 's/[[:space:]]\+$//' file.txt

# Squeeze blank lines (keep at most one)
sed '/^$/{N;/^\n$/d}' file.txt

# Print every 2nd line
sed -n '1~2p' file.txt

# Line numbering (like cat -n)
sed = file.txt | sed 'N;s/\n/ /'

# Remove lines 2-5
sed '2,5d' file.txt

# Add a blank line after each line
sed G file.txt

# Extract text between markers (non-greedy)
sed -n '/START/{:a;n;/END/{p;d};H;ba};${g;p}' file.txt
```

---

## 5. awk — Text Processing Language

`awk` is a full programming language for text processing. Pattern → action, fields, associative arrays.

### 5.1 awk Program Structure

```awk
BEGIN { actions }          # before first line
/pattern/ { actions }      # for matching lines
{ actions }                # for every line
END { actions }            # after last line
```

```bash
awk '{ print $1 }' file.txt            # first field
awk '/ERROR/ { print $0 }' log.txt     # lines with ERROR
awk '$3 > 100 { print $1, $2 }' data   # conditional
```

### 5.2 Fields and Records

```bash
# Default: whitespace-separated fields ($1, $2, ..., $NF)
awk '{ print $1, $3 }' /etc/passwd     # username, UID

# $0 = entire line, $NF = last field
awk '{ print $NF }' file.txt           # last column

# Number of fields
awk '{ print NF, $0 }' file.txt        # count fields per line

# Custom field separator
awk -F: '{ print $1, $6 }' /etc/passwd  # user, home dir
awk -F'[,;]' '{ print $1, $2 }' data    # comma or semicolon
```

### 5.3 BEGIN and END Blocks

```bash
awk 'BEGIN { print "Report Started" } 
     { print NR, $0 } 
     END { print "Total lines:", NR }' file.txt

# Running totals
awk 'BEGIN { sum=0; count=0 }
     { sum += $1; count++ }
     END { print "Average:", sum/count }' numbers.txt

# Header + footer
awk -F, 'BEGIN { print "NAME,AGE,CITY" }
             { print $1","$2","$3 }
         END { print "--- END ---" }' data.csv
```

### 5.4 Variables and Built-ins

```bash
# Built-in variables
NR      # current record number (line)
NF      # number of fields in current record
FS      # field separator (default: space/tab)
OFS     # output field separator (default: space)
RS      # record separator (default: newline)
ORS     # output record separator (default: newline)
FILENAME # current input file
FNR     # record number relative to current file
```

```bash
awk '{ print NR":", $0 }' file.txt         # line numbers
awk 'FNR==1 { print FILENAME }' *.txt      # print filename at start of each file
awk -v OFS=',' '{ print $1, $2 }' file     # comma-separated output
```

### 5.5 printf for Formatted Output

```bash
awk '{ printf "%-20s %8d\n", $1, $2 }' file.txt

# Format specifiers
%s    # string
%d    # decimal integer
%f    # floating point
%x    # hexadecimal
%e    # scientific notation
%-Ns  # left-justified, N width
%N.Mf # N width, M decimal places
```

```bash
# Column alignment
awk -F: '{ printf "%-15s %-5s %s\n", $1, $3, $6 }' /etc/passwd

# Currency formatting
awk '{ printf "$%8.2f\n", $1 * 1.1 }' prices.txt

# Table with separators
awk 'BEGIN { printf "+%-20s+%-10s+\n", "--------------", "--------" }
          { printf "|%-20s|%-10s|\n", $1, $2 }
     END { printf "+%-20s+%-10s+\n", "--------------", "--------" }' data.txt
```

### 5.6 Associative Arrays

Arrays are indexed by strings (associative), not numbers.

```bash
# Count occurrences
awk '{ count[$1]++ } END { for (k in count) print k, count[k] }' file.txt

# Two-dimensional simulation
awk '{ data[$1,$2] = $3 } END { print data["foo","bar"] }' file.txt

# Group by field
awk '{ dept[$2] += $3 } END { for (d in dept) print d, dept[d] }' sales.csv

# Unique values
awk '!seen[$0]++' file.txt                  # like sort -u
awk '!seen[$1]++ { print $1 }' file.txt     # unique first field

# Delete in array
awk '{ if ($1 in cache) delete cache[$1]; cache[$1] = $0 }' file.txt
```

### 5.7 Control Flow

```bash
if (condition) action
if (condition) action else action
for (init; test; inc) action
for (key in array) action
while (condition) action
do action while (condition)
break / continue
next     # skip to next record
exit     # exit with optional code
```

```bash
# If-else
awk '{ if ($3 > 1000) print $1, "HIGH"; else print $1, "LOW" }' data.txt

# For loop
awk '{ for (i=1; i<=NF; i++) if ($i ~ /error/) print NR, $i }' log.txt

# While loop
awk '{ i=1; while (i<=NF) { print $i; i++ } }' file.txt

# Next — skip rest of actions for this record
awk '/^#/ { next } { print $0 }' config.conf
```

### 5.8 Pattern Matching

```bash
~       # matches regex
!~      # does NOT match regex
==, !=, <, >, <=, >=   # comparisons
&&, ||, !              # logical operators
```

```bash
awk '$1 ~ /^root/' /etc/passwd              # username starts with root
awk '$0 !~ /^#|^$/' /etc/ssh/sshd_config    # non-comment, non-blank
awk '$3 >= 500 && $3 < 1000' /etc/passwd    # UID range
awk -F: '$7 ~ /bash$/' /etc/passwd          # bash users
```

### 5.9 Built-in Functions

```bash
length(s)     # string length
substr(s, i, n) # substring from i, length n
index(s, t)   # position of t in s (1-based), 0 if not found
match(s, r)   # position of regex match
split(s, a, f) # split string s into array a using f
gsub(r, t, s) # global substitution in s
sub(r, t, s)  # first substitution in s
toupper(s)    # uppercase
tolower(s)    # lowercase
sprintf(fmt, args) # formatted string
int(x)        # integer truncation
rand()        # random number 0-1
srand(x)      # seed random
system(cmd)   # execute shell command
strftime(fmt) # formatted time
```

```bash
# String ops
awk '{ print length($0), $0 }' file.txt     # line lengths
awk '{ print substr($1, 1, 3) }' file.txt   # first 3 chars

# Math
awk '{ sum += $1; sumsq += $1^2 } END { print "stddev:", sqrt(sumsq/NR - (sum/NR)^2) }'

# System interaction
awk '{ system("ls -la " $1) }' files.txt

# Time formatting
awk 'BEGIN { print strftime("%Y-%m-%d %H:%M:%S") }'
```

### 5.10 User-Defined Functions

```bash
awk '
function max(a, b) {
    return a > b ? a : b
}
{ print max($1, $2) }
' file.txt

# Multi-line function (put in script.awk)
# function is_ip(ip) {
#     split(ip, octets, ".")
#     if (length(octets) != 4) return 0
#     for (i in octets) if (octets[i] < 0 || octets[i] > 255) return 0
#     return 1
# }
```

---

## 6. awk Admin Patterns

### 6.1 Log Parsing

```bash
# Apache/Nginx access log analysis
awk '{ print $1 }' access.log | sort | uniq -c | sort -rn | head -10
awk '{ print $9 }' access.log | sort | uniq -c | sort -rn

# HTTP status code counts from Apache combined format
# Format: IP - - [date] "METHOD URL PROTO" STATUS SIZE "REFERER" "UA"
awk '{
    status = $9
    if (status ~ /^[0-9]+$/) {
        if (status ~ /^2/) group = "2xx Success"
        else if (status ~ /^3/) group = "3xx Redirect"
        else if (status ~ /^4/) group = "4xx Client Error"
        else if (status ~ /^5/) group = "5xx Server Error"
        else group = "Other"
        counts[group]++
        total++
    }
} END {
    for (g in counts) printf "%-20s %5d (%.1f%%)\n", g, counts[g], counts[g]/total*100
}' access.log

# 404 by URL
awk '$9 == 404 { print $7 }' access.log | sort | uniq -c | sort -rn | head -20

# Response time > 5 seconds (if in log)
awk '{
    split($NF, t, "/")
    if (t[1] > 5) print $1, $7, t[1]
}' access.log
```

### 6.2 CSV Data Extraction

```bash
# CSV with possible quoted fields
awk -F',' '{
    # Strip quotes from fields
    for (i=1; i<=NF; i++) {
        gsub(/^"|"$/, "", $i)
    }
    print $1, $3
}' data.csv

# Filter rows where column 2 > 100
awk -F, '$2+0 > 100 { print $1, $2 }' data.csv

# Extract specific columns
awk -F, '{ print $1, $4, $7 }' OFS=',' employees.csv

# CSV with header
awk -F, 'NR==1 { print "HEADER:", $0 } NR>1 { print "DATA:", $1 }' file.csv
```

### 6.3 Summarization

```bash
# Total, average, min, max
awk '{
    sum += $1
    count++
    if ($1 > max) max = $1
    if (min == "" || $1 < min) min = $1
} END {
    print "Count:", count
    print "Sum:", sum
    print "Avg:", sum/count
    print "Min:", min
    print "Max:", max
}' numbers.txt

# Group by category
awk -F, '{
    cat = $2
    count[cat]++
    total[cat] += $3
} END {
    for (c in count) printf "%-20s Count: %5d Total: %8.2f\n", c, count[c], total[c]
}' sales.csv

# Top-N by group
awk -F, '{
    items[$1][$2] = $3
} END {
    for (cat in items) {
        print "Category:", cat
        n = asorti(items[cat], sorted, "@val_num_desc")
        for (i=1; i<=3 && i<=n; i++) print "  ", sorted[i], items[cat][sorted[i]]
    }
}' data.csv
```

### 6.4 Report Generation

```bash
#!/bin/bash
# report.sh — generates system summary report with awk

{
    echo "============================================"
    echo "  SYSTEM REPORT - $(date)"
    echo "============================================"
    echo ""
    echo "--- DISK USAGE ---"
    df -h | awk 'NR==1 || int($5) > 80 { print $0 }'
    echo ""
    echo "--- TOP MEMORY PROCESSES ---"
    ps aux | awk 'NR==1 { print $0 } NR>1 { print $0 | "sort -k4 -rn" }' | head -6
    echo ""
    echo "--- FAILED LOGIN ATTEMPTS ---"
    journalctl -u sshd --since "24 hours ago" | grep "Failed password" | \
        awk '{ print $11 }' | sort | uniq -c | sort -rn | head -10
    echo ""
    echo "--- NETWORK CONNECTIONS ---"
    ss -tuna | awk 'NR>1 { print $5 }' | awk -F: '{ print $1 }' | sort | uniq -c | sort -rn | head -10
    echo ""
    echo "--- END REPORT ---"
}
```

### 6.5 Columnar Output

```bash
# Format passwd as a table
awk -F: 'BEGIN {
    printf "%-20s %-6s %-6s %-30s %-20s\n", "Username", "UID", "GID", "Home", "Shell"
    printf "%-20s %-6s %-6s %-30s %-20s\n", "--------", "---", "---", "----", "-----"
}
{
    printf "%-20s %-6s %-6s %-30s %-20s\n", $1, $3, $4, $6, $7
}' /etc/passwd

# Expand tabs to aligned columns
awk -v OFS='\t' '{ $1=$1; print }' file.txt | column -t -s $'\t'
```

### 6.6 Two-File Processing

```bash
# Process two files using NR and FNR
awk 'NR==FNR { ids[$1]=1; next } $1 in ids { print $0 }' ids.txt data.txt

# Join on first field
awk 'NR==FNR { a[$1]=$2; next } $1 in a { print $0, a[$1] }' lookup.txt main.txt

# Diff two files
awk 'NR==FNR { a[$0]=1; next } !($0 in a)' file1 file2   # lines in file2 not in file1
```

---

## 7. Combining Tools

### 7.1 Piping sed + awk + grep

```bash
# Pipeline: extract, transform, summarize
grep -E '^[0-9]{2}/[A-Za-z]{3}/[0-9]{4}' access.log | \
    sed 's/\[//g; s/\]//g' | \
    awk '{ print $1, $4 }' | \
    sort | uniq -c | sort -rn | head -20

# Find all config files, extract port settings
find /etc -name '*.conf' -exec grep -l '^port\b' {} \; | \
    xargs awk '/^port\s/ { print FILENAME, $0 }' | \
    sed 's/:\s*/ = /'

# Parse syslog, filter severity, format output
grep CRITICAL /var/log/syslog | \
    sed 's/^[A-Za-z0-9 ]* [0-9:]* //' | \
    awk '{ printf "[%-5s] %s\n", $1, $0 }' | \
    column -t
```

### 7.2 Extracting Structured Data From Unstructured Logs

```bash
#!/bin/bash
# parse_multiline_log.sh — extract multi-line stack traces

# Input: Java stack traces spanning multiple lines
# Output: One line per exception: timestamp, type, message

grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2}|Exception|Caused by' app.log | \
    awk '
    /^[0-9]{4}-/ {
        if (exc) print ts, exc, msg
        ts = $1" "$2
        exc = ""
        msg = ""
        next
    }
    /Exception/ {
        exc = $0
        next
    }
    /Caused by/ {
        if (!msg) msg = $0
    }
    END {
        if (exc) print ts, exc, msg
    }' | \
    column -t
```

### 7.3 Processing Output of Other Commands

```bash
# Disk usage by user (requires quota)
find /home -maxdepth 1 -type d | while read dir; do
    du -sk "$dir" 2>/dev/null
done | awk '{total += $1; print $0} END {print "Total (MB):", total/1024}'

# Package sizes (Debian)
dpkg-query -Wf '${Installed-Size} ${Package}\n' | \
    sort -rn | \
    awk 'BEGIN {print "Package Size (MB)"} {printf "%-30s %5.2f\n", $2, $1/1024}' | \
    head -20

# Process tree
ps -eo pid,ppid,cmd --no-headers | \
    awk '{ children[$2] = children[$2] " " $1; procs[$1] = $3 }
    END {
        for (p in procs) {
            printf "%s (%s)\n", procs[p], p
            if (children[p]) {
                split(children[p], kids)
                for (i in kids) printf "  \\_ %s (%s)\n", procs[kids[i]], kids[i]
            }
        }
    }'
```

---

## 8. cut, sort, uniq, wc, tr

### 8.1 cut — Column Extraction

```bash
cut -d: -f1,3 /etc/passwd          # fields 1 and 3 (delimiter :)
cut -d: -f1-3 /etc/passwd          # fields 1 through 3
cut -c1-10 file.txt                # characters 1-10
cut -d, -f1 --complement data.csv  # all except field 1
cut -d' ' -f2-                     # from field 2 to end
```

### 8.2 sort — Line Sorting

```bash
sort file.txt                      # alphabetically
sort -n file.txt                   # numerically
sort -rn file.txt                  # reverse numerically
sort -k2 -t: /etc/passwd           # sort by field 2, delimiter :
sort -u file.txt                   # unique sort
sort -h file.txt                   # human numeric (2K, 3M, 1G)
sort -R file.txt                   # random sort
sort -m file1 file2                # merge already-sorted files
sort -t$'\t' -k3 -n data.tsv       # tab-delimited, numeric field 3
```

### 8.3 uniq — Unique Lines

```bash
uniq file.txt                      # remove adjacent duplicates
uniq -c file.txt                   # prefix with count
uniq -d file.txt                   # only duplicates
uniq -u file.txt                   # only unique (non-duplicate) lines
sort file.txt | uniq               # global unique (sort first)
sort file.txt | uniq -c | sort -rn # frequency table
```

### 8.4 wc — Word Count

```bash
wc file.txt                        # lines, words, bytes
wc -l file.txt                     # lines only
wc -w file.txt                     # words only
wc -c file.txt                     # bytes
wc -m file.txt                     # characters (multi-byte aware)
wc -L file.txt                     # longest line length
```

### 8.5 tr — Translate/Delete

```bash
tr 'a-z' 'A-Z' < file.txt          # uppercase
tr -d '\t' < file.txt              # delete tabs
tr -s ' ' ' ' < file.txt           # squeeze spaces
tr -d '\r' < dos.txt > unix.txt    # remove CR (DOS→Unix)
tr ' ' '\n' < file.txt             # split words to lines
tr -dc '[:print:]' < file.txt      # delete non-printable chars
tr '[:upper:]' '[:lower:]' < file.txt  # lowercase (locale-aware)
```

### 8.6 Practical Pipelines

```bash
# Top 10 most frequent words
tr -s '[:space:]' '\n' < file.txt | tr -d '[:punct:]' | sort | uniq -c | sort -rn | head -10

# Largest files in directory
ls -la | awk 'NR>1 {print $5, $NF}' | sort -rn | head -10

# IP connections count
ss -tuna | awk 'NR>1 {print $5}' | cut -d: -f1 | sort | uniq -c | sort -rn | head -10

# HTTP status code summary
awk '{print $9}' access.log | sort | uniq -c | sort -rn

# Users with UID > 1000 (non-system)
awk -F: '$3 >= 1000 {print $1, $3}' /etc/passwd | sort -k2 -n

# File type breakdown
find . -type f | awk -F. '{print $NF}' | sort | uniq -c | sort -rn
```

---

## 9. paste, join, comm

### 9.1 paste — Merge Lines Column-Wise

```bash
# Side by side
paste file1 file2                   # tab-delimited columns
paste -d, file1 file2              # comma delimiter
paste -d'|' file1 file2            # pipe delimiter

# Serial paste
paste -s file1                     # all lines on one line (tab)
paste -sd, file1                   # all lines, comma-separated

# Interleave lines
paste - - < file.txt               # pairs of lines
paste - - - < file.txt             # groups of 3 lines
```

```bash
# Combine header and data
echo "User:UID:Shell" | cat - /etc/passwd | head -1

# Create CSV from columns
paste -d, users.txt uids.txt shells.txt
```

### 9.2 join — Relational Join on Common Field

```bash
# Requires sorted input
join -t: -1 1 -2 1 users.txt groups.txt     # join on field 1
join -t, -j1 -o 1.1,2.2 file1.csv file2.csv

# Outer joins
join -a1 file1 file2              # left outer join
join -a2 file1 file2              # right outer join
join -a1 -a2 file1 file2          # full outer join

# Custom output format
join -o 1.1,2.2,1.3 -t: /etc/passwd /etc/group
# 1.1 = file1 field1, 2.2 = file2 field2, 1.3 = file1 field3
```

```bash
# Example: join passwd with group info
sort -t: -k4 /etc/passwd > passwd_by_gid
sort -t: -k3 /etc/group > group_by_gid
join -t: -1 4 -2 3 -o 1.1,2.1 passwd_by_gid group_by_gid | head
```

### 9.3 comm — Compare Two Sorted Files

```bash
comm file1 file2                   # 3-column output
comm -1 file1 file2                # suppress column 1
comm -2 file1 file2                # suppress column 2
comm -3 file1 file2                # suppress column 3
comm -12 file1 file2               # only lines in both (intersection)
comm -23 file1 file2               # lines only in file1
comm -13 file1 file2               # lines only in file2
```

```bash
# Compare package lists between two servers
ssh server1 'dpkg -l | awk "NR>5 {print \$2}"' | sort > pkgs_1.txt
ssh server2 'dpkg -l | awk "NR>5 {print \$2}"' | sort > pkgs_2.txt
comm -3 pkgs_1.txt pkgs_2.txt      # differences
comm -12 pkgs_1.txt pkgs_2.txt     # common packages
```

---

## 10. xargs — Building Command Lines from stdin

### 10.1 Basic Usage

```bash
# Convert stdin to arguments
find . -name '*.tmp' | xargs rm -f

# With -I for substitution
find . -name '*.txt' | xargs -I {} cp {} /backup/

# Dry run
find . -name '*.tmp' | xargs -I {} echo rm {}

# Null-separated (safe with spaces)
find . -name '*.txt' -print0 | xargs -0 rm -f
```

### 10.2 Key Options

```bash
-n N       # max arguments per command
-I {}      # replacement string
-P N       # parallel N processes
-0 / --null # null-delimited input
-t         # trace (print commands before running)
-p         # prompt before running each command
-r         # don't run if stdin is empty (GNU)
-d CHAR    # custom delimiter
```

```bash
# Batch files (100 per rm call)
find . -name '*.log' | xargs -n 100 rm -f

# Parallel downloads
cat urls.txt | xargs -P 4 -n 1 wget -q

# With replacement string
seq 1 10 | xargs -I {} echo "Processing file_{}.txt"

# Prompt before dangerous operations
find . -name '*.zip' -type f | xargs -p rm
```

### 10.3 Parallel xargs (-P)

```bash
# Parallel compression
find /var/log -name '*.log' -mtime +30 | \
    xargs -P $(nproc) -I {} gzip {}

# Parallel DNS lookup
cat domains.txt | xargs -P 10 -n 1 dig +short

# Parallel file processing
find data/ -name '*.csv' | \
    xargs -P 4 -I {} sh -c 'wc -l "$1" | awk "{print \$1, \"$1\"}"' -- {}
```

### 10.4 xargs with find (Best Practices)

```bash
# BAD: special chars break
find . -name '*.txt' | xargs rm

# GOOD: null separator
find . -name '*.txt' -print0 | xargs -0 rm

# BEST: use -exec or -delete
find . -name '*.txt' -delete
find . -name '*.txt' -exec rm {} +
```

### 10.5 xargs for System Admin

```bash
# Restart services from file
grep -l 'status: fail' /etc/service/* | sed 's|.*/||' | xargs -I {} systemctl restart {}

# Check multiple hosts
echo "web{1,2,3}.example.com" | tr ',' '\n' | xargs -P 3 -I {} ssh {} 'uptime'

# Kill processes by name
pgrep -f 'node server.js' | xargs kill -9

# Chown files by owner
awk -F: '$1 == "www-data" {print $6}' /etc/passwd | xargs -I {} chown -R www-data:www-data {}
```

---

## 11. diff and patch

### 11.1 diff — Compare Files

```bash
diff file1 file2                   # normal format
diff -u file1 file2               # unified format (most common)
diff -c file1 file2               # context format
diff -Naur dir1/ dir2/            # recursive, new/absent as empty
diff -rq dir1/ dir2/              # recursive, only which differ
diff -y file1 file2               # side by side
diff -w file1 file2               # ignore whitespace
diff -i file1 file2               # ignore case
```

### 11.2 Creating Patches

```bash
# Unified diff (standard for patches)
diff -u original.c modified.c > fix.patch

# Recursive directory patch
diff -Naur orig/ new/ > changes.patch

# Git-style (no timestamps in headers)
diff -u original.c modified.c | grep -v '^[+-]{3}' > clean.patch
```

### 11.3 Applying Patches

```bash
patch < fix.patch                  # apply to working dir
patch -p0 < fix.patch             # strip 0 path components
patch -p1 < fix.patch             # strip 1 path component
patch -R < fix.patch              # reverse (undo)
patch --dry-run < fix.patch       # test without applying

# Applying directory patches
cd /usr/src/nginx-1.24.0/
patch -p1 < /path/to/nginx-security.patch
```

### 11.4 Admin Use Cases

```bash
# Verify config changes
diff -u /etc/ssh/sshd_config.bak /etc/ssh/sshd_config

# Package file integrity
dpkg --verify | awk '$1 ~ /^[^ ]/ {print $0}'

# Document changes before deployment
diff -rq /etc/nginx/ /etc/nginx.staging/ | grep -v '.git'

# Roll back config
patch -R < /var/backups/sshd_config.$(date +%F).patch

# Compare two servers' package lists
ssh server1 'dpkg -l' | awk 'NR>5 {print $2, $3}' | sort > svr1.txt
ssh server2 'dpkg -l' | awk 'NR>5 {print $2, $3}' | sort > svr2.txt
diff -u svr1.txt svr2.txt
```

---

## 12. Real-World Admin Scripts

### 12.1 Log Parser — Extract, Summarize, Report

```bash
#!/bin/bash
# log_analyzer.sh — analyze web server access log
# Usage: ./log_analyzer.sh /var/log/nginx/access.log

LOG="${1:-/var/log/nginx/access.log}"

if [ ! -r "$LOG" ]; then
    echo "Error: cannot read $LOG"
    exit 1
fi

echo "=========================================="
echo "  LOG ANALYZER REPORT"
echo "  File: $LOG"
echo "  Date: $(date)"
echo "=========================================="
echo ""

# Total requests
total=$(wc -l < "$LOG")
echo "Total requests: $total"

# Unique IPs
echo -n "Unique IPs:      "
awk '{print $1}' "$LOG" | sort -u | wc -l

# Status code distribution
echo ""
echo "--- Status Code Distribution ---"
awk '{
    code = $9
    codes[code]++
} END {
    for (c in codes) printf "  %s: %d\n", c, codes[c]
}' "$LOG" | sort -t: -k2 -rn

# Top 10 IPs
echo ""
echo "--- Top 10 IPs ---"
awk '{print $1}' "$LOG" | sort | uniq -c | sort -rn | head -10 | \
    awk '{ printf "  %-15s %d requests\n", $2, $1 }'

# Top 10 URLs
echo ""
echo "--- Top 10 URLs ---"
awk '{print $7}' "$LOG" | sort | uniq -c | sort -rn | head -10 | \
    awk '{ printf "  %-50s %d requests\n", $2, $1 }'

# 404 analysis
echo ""
echo "--- 404 Errors by URL ---"
awk '$9 == 404 {print $7}' "$LOG" | sort | uniq -c | sort -rn | head -10 | \
    awk '{ printf "  %-50s %d times\n", $2, $1 }'

# Hourly distribution
echo ""
echo "--- Requests by Hour ---"
awk '{
    match($4, /[0-9]{2}\/[A-Za-z]{3}\/[0-9]{4}:([0-9]{2})/, h)
    if (h[1] != "") hours[h[1]]++
} END {
    for (h=0; h<24; h++) {
        kh = sprintf("%02d", h)
        bar = ""
        for (i=0; i<hours[kh]/50; i++) bar = bar "#"
        printf "  %s: %5d %s\n", kh, hours[kh], bar
    }
}' "$LOG"

echo ""
echo "--- End of Report ---"
```

### 12.2 Config Generator — Templating with sed + awk

```bash
#!/bin/bash
# config_gen.sh — generate nginx configs from template
# Usage: ./config_gen.sh site_name domain port

set -euo pipefail

SITE="${1:?Usage: $0 site_name domain port}"
DOMAIN="${2:?}"
PORT="${3:?}"

TEMPLATE="/etc/nginx/templates/site.template"
OUTPUT="/etc/nginx/sites-available/${SITE}"

if [ ! -f "$TEMPLATE" ]; then
    echo "Template not found: $TEMPLATE"
    exit 1
fi

# Generate config using sed
sed -e "s/{{SITE}}/$SITE/g" \
    -e "s/{{DOMAIN}}/$DOMAIN/g" \
    -e "s/{{PORT}}/$PORT/g" \
    -e "s/{{DATE}}/$(date)/g" \
    -e "s/{{ADMIN}}/${ADMIN_EMAIL:-admin@$DOMAIN}/g" \
    "$TEMPLATE" > "$OUTPUT"

echo "Generated: $OUTPUT"

# Validate and enable
if nginx -t 2>&1 | grep -q successful; then
    ln -sf "$OUTPUT" /etc/nginx/sites-enabled/
    systemctl reload nginx
    echo "Site enabled: $SITE"
else
    echo "NGINX config test FAILED. Check $OUTPUT"
    nginx -t
    exit 1
fi
```

### 12.3 Inventory Report — System Audit

```bash
#!/bin/bash
# inventory.sh — generate system inventory report
# Output: CSV with hostname, os, kernel, cpu, mem, disk

OUTPUT="${1:-inventory_$(hostname)_$(date +%Y%m%d).csv}"

echo "hostname,os,kernel,cpu_cores,mem_gb,disk_gb,ip_address" > "$OUTPUT"

OS=$(awk -F= '/^NAME/{gsub(/"/,"",$2); print $2}' /etc/os-release)
KERNEL=$(uname -r)
CPU=$(nproc)
MEM=$(awk '/MemTotal/{printf "%.1f", $2/1024/1024}' /proc/meminfo)
DISK=$(df -h / | awk 'NR==2 {print $2}')
IP=$(hostname -I 2>/dev/null | awk '{print $1}')

echo "$(hostname),$OS,$KERNEL,$CPU,$MEM,$DISK,$IP" >> "$OUTPUT"

# For multiple servers
# cat servers.txt | xargs -P10 -I{} ssh {} 'bash -s' < inventory.sh

echo "Inventory written to: $OUTPUT"
```

### 12.4 CSV-to-HTML Converter

```bash
#!/bin/bash
# csv2html.sh — convert CSV to HTML table
# Usage: ./csv2html.sh data.csv > report.html

CSV="${1:?Usage: $0 file.csv}"
TITLE="${2:-CSV Report}"

if [ ! -r "$CSV" ]; then
    echo "Error: cannot read $CSV"
    exit 1
fi

cat <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>$TITLE</title>
<style>
  table { border-collapse: collapse; width: 100%; }
  th, td { border: 1px solid #999; padding: 8px; text-align: left; }
  th { background-color: #4CAF50; color: white; }
  tr:nth-child(even) { background-color: #f2f2f2; }
</style>
</head>
<body>
<h1>$TITLE</h1>
<p>Generated: $(date)</p>
<table>
EOF

awk -F, '
BEGIN {
    row = 0
}
{
    row++
    if (row == 1) {
        printf "<thead>\n<tr>\n"
        for (i=1; i<=NF; i++) {
            gsub(/^"|"$/, "", $i)
            printf "<th>%s</th>\n", $i
        }
        printf "</tr>\n</thead>\n<tbody>\n"
    } else {
        printf "<tr>\n"
        for (i=1; i<=NF; i++) {
            gsub(/^"|"$/, "", $i)
            printf "<td>%s</td>\n", $i
        }
        printf "</tr>\n"
    }
}
END {
    printf "</tbody>\n</table>\n</body>\n</html>\n"
}' "$CSV"
```

### 12.5 Log Watchdog — Multi-tool Alerting

```bash
#!/bin/bash
# log_watchdog.sh — monitor logs and trigger alerts
# Uses grep, sed, awk, mail

LOG="${1:-/var/log/syslog}"
PATTERNS="ERROR|FATAL|PANIC|CRITICAL|OOM|killed"
STATE_FILE="/tmp/log_watchdog_last"
SLEEP=60
ALERT_EMAIL="root@localhost"

while true; do
    skip=$(cat "$STATE_FILE" 2>/dev/null || echo 0)

    # Use sed to skip already-processed lines
    matches=$(tail -n +$((skip + 1)) "$LOG" | \
        grep -E "$PATTERNS" | \
        sed 's/^/ALERT: /')

    if [ -n "$matches" ]; then
        echo "$matches" | \
            awk '{ printf "[%s] %s\n", strftime("%H:%M:%S"), $0 }' | \
            while read line; do
                logger -t log_watchdog "$line"
                echo "$line" | mail -s "ALERT from $(hostname)" "$ALERT_EMAIL"
            done
    fi

    # Update state
    wc -l < "$LOG" > "$STATE_FILE"
    sleep "$SLEEP"
done
```

### 12.6 Parallel Log Analyzer (xargs -P)

```bash
#!/bin/bash
# parallel_log_analysis.sh — analyze multiple log files in parallel
# Usage: ./parallel_log_analysis.sh /var/log/*.log

analyze_file() {
    local file="$1"
    local errors warnings total

    errors=$(grep -ci 'error\|fatal\|panic' "$file" 2>/dev/null || echo 0)
    warnings=$(grep -ci 'warn' "$file" 2>/dev/null || echo 0)
    total=$(wc -l < "$file" 2>/dev/null || echo 0)

    printf "[%s] %s errors=%d warnings=%d total=%d\n" \
        "$(date -r "$file" '+%Y-%m-%d %H:%M')" \
        "$(basename "$file")" "$errors" "$warnings" "$total"
}

export -f analyze_file

if [ $# -eq 0 ]; then
    echo "Usage: $0 <logfile> [logfile ...]"
    exit 1
fi

echo "Parallel analysis of $# files..."
printf "%s\0" "$@" | xargs -0 -P "$(nproc)" -I {} bash -c 'analyze_file "$@"' _ {}
```

---

## ⭐ Level 3: Advanced — Practices & Internals

![Advanced terminal](https://upload.wikimedia.org/wikipedia/commons/a/a5/Terminal_icon.svg)

> *"There is no substitute for practice. Internals knowledge turns users into masters."*

---

## 13. Hands-On Practices (15)

### Level 1 — Basic

#### Practice 1: grep Patterns
Find all lines in `/var/log/syslog` that contain either "ERROR" or "FATAL" (case-insensitive), print only the matching text, and prefix with line numbers.
```bash
grep -inoE 'ERROR|FATAL' /var/log/syslog
```

#### Practice 4: Pipe Pipeline for System Analysis
Build a one-liner that shows top 5 CPU-eating processes with PID, command, and CPU%, formatted as a table.
```bash
ps aux --no-headers | sort -k3 -rn | head -5 | \
    awk '{ printf "%-8s %-30s %5.1f%%\n", $2, $11, $3 }'
```

#### Practice 6: Create a CSV Report with awk
Generate a report of all users with UID ≥ 1000, showing username, UID, home directory, and shell, as a CSV.
```bash
awk -F: '$3 >= 1000 { printf "%s,%s,%s,%s\n", $1, $3, $6, $7 }' /etc/passwd > users.csv
```

#### Practice 7: Apply Patches with diff/patch
Create a patch from two versions of a config file, then apply and revert it.
```bash
diff -u /etc/nginx/nginx.conf.bak /etc/nginx/nginx.conf > nginx.patch
sudo patch < nginx.patch
sudo patch -R < nginx.patch
```

#### Practice 11: Text Processing with tr, cut, sort
Extract the domain portion from email addresses in a file, sort, and count unique domains.
```bash
tr -s '[:space:]' '\n' < emails.txt | grep -oE '@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' | \
    tr -d '@' | sort | uniq -c | sort -rn
```

#### Practice 13: join/paste Data Merging
Create a CSV by joining `/etc/passwd` (UID) with `/etc/group` (GID) to map each user to their primary group name.
```bash
sort -t: -k4 /etc/passwd > pwd_sorted
sort -t: -k3 /etc/group > grp_sorted
join -t: -1 4 -2 3 -o 1.1,2.1,1.3 pwd_sorted grp_sorted | head
```

### Level 2 — Intermediary

#### Practice 2: sed Search/Replace in Config
Edit `/etc/ssh/sshd_config` to change `#Port 22` to `Port 2222` (uncomment and change value), creating a backup first.
```bash
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
sudo sed -i 's/^#\s*Port\s\+22/Port 2222/' /etc/ssh/sshd_config
```

#### Practice 3: awk Log Parser
Using `/var/log/auth.log`, extract all IP addresses from "Failed password" lines, count occurrences, and display top 10.
```bash
awk '/Failed password/ {
    for (i=1; i<=NF; i++) if ($i ~ /^[0-9]{1,3}\./) ips[$i]++
} END {
    for (ip in ips) print ips[ip], ip
}' /var/log/auth.log | sort -rn | head -10
```

#### Practice 5: xargs Parallel Task Execution
Find all `.conf` files under `/etc`, validate them with `nginx -t`, and restart nginx if all pass, using parallel xargs.
```bash
find /etc/nginx -name '*.conf' -print0 | xargs -0 -P4 -I{} nginx -t -c {} 2>&1
```

#### Practice 8: Multi-tool Log Analysis Pipeline
Count 404 errors per URL from an Apache/Nginx log, sorted by frequency, with human-readable output.
```bash
awk '$9 == 404 {print $7}' /var/log/nginx/access.log | sort | uniq -c | sort -rn | \
    awk '{ printf "%-6d %s\n", $1, $2 }' | head -20
```

#### Practice 9: sed Multi-File Config Update
Update `max_connections` in all `.conf` files under `/etc/mysql/` from 100 to 500, with backups.
```bash
find /etc/mysql -name '*.conf' -exec sh -c 'cp "$1" "$1.bak"; sed -i "s/max_connections=100/max_connections=500/" "$1"' _ {} \;
```

#### Practice 10: awk Report with Grouping and Totals
Parse `df -h` output and produce a report sorted by usage percentage, with a total line at the end.
```bash
df -h | awk 'NR>1 {
    pct = $5
    gsub(/%/, "", pct)
    if (pct+0 > 0) {
        printf "%-20s %6s %5s\n", $1, $5, $3
        total += pct
        count++
    }
} END {
    printf "%-20s %6s\n", "Average Usage:", int(total/count)"%"
}'
```

#### Practice 14: awk Inline Script
Write an awk one-liner that takes `ps aux` output and prints processes where RSS > 100MB (RSS field is $6, in KB).
```bash
ps aux --no-headers | awk '$6 > 102400 { printf "%-10s %-30s %6.1f MB\n", $1, $11, $6/1024 }'
```

### Level 3 — Advanced

#### Practice 12: sed Multi-Line Replacement
Replace multi-line `<div class="old">...</div>` blocks with `<div class="new">...</div>` in HTML files.
```bash
sed -i '/<div class="old">/,/<\/div>/c\<div class="new">\n  <!-- updated -->\n</div>' file.html
```

#### Practice 15: Real-World Integration
Build a complete log analysis and reporting toolkit script that:
1. Parses a web access log
2. Extracts top IPs, URLs, status codes, hourly distribution
3. Anonymizes IPs for GDPR compliance
4. Outputs both a summary report (text) and a CSV file
5. Uses at least grep, sed, awk, sort, uniq, and optionally xargs

```bash
#!/bin/bash
# complete_log_toolkit.sh — full log analysis pipeline
# Usage: ./complete_log_toolkit.sh access.log [output_dir]

LOG="${1:?Usage: $0 access.log [output_dir]}"
OUTDIR="${2:-./analysis_$(date +%Y%m%d_%H%M%S)}"
mkdir -p "$OUTDIR"

ANON_LOG="${OUTDIR}/access_anonymized.log"
REPORT="${OUTDIR}/report.txt"
CSV="${OUTDIR}/summary.csv"

echo "Analyzing: $LOG"
echo "Output:    $OUTDIR"
echo ""

# Step 1: Anonymize IPs (last octet → .0)
echo "[1/5] Anonymizing IPs..."
sed -E 's/([0-9]{1,3}\.){3}[0-9]{1,3}/\1**0/g' "$LOG" > "$ANON_LOG"
echo "  Wrote: $ANON_LOG"

# Step 2: Generate text report
echo "[2/5] Generating text report..."
{
    echo "=========================================="
    echo "  LOG ANALYSIS REPORT"
    echo "  Source: $LOG"
    echo "  Generated: $(date)"
    echo "=========================================="
    echo ""

    total=$(wc -l < "$LOG")
    echo "Total requests: $total"

    echo ""
    echo "--- Top 10 IPs ---"
    awk '{print $1}' "$LOG" | sort | uniq -c | sort -rn | head -10

    echo ""
    echo "--- Top 10 URLs ---"
    awk '{print $7}' "$LOG" | sort | uniq -c | sort -rn | head -10

    echo ""
    echo "--- Status Codes ---"
    awk '{print $9}' "$LOG" | sort | uniq -c | sort -rn

    echo ""
    echo "--- Hourly Distribution ---"
    awk '{
        match($4, /[0-9]{2}\/[A-Za-z]{3}\/[0-9]{4}:([0-9]{2})/, h)
        if (h[1] != "") hours[h[1]]++
    } END {
        for (h=0; h<24; h++) {
            kh = sprintf("%02d", h)
            printf "  %s: %d\n", kh, hours[kh]
        }
    }' "$LOG"

    echo ""
    echo "--- 404 Errors (top 10) ---"
    awk '$9 == 404 {print $7}' "$LOG" | sort | uniq -c | sort -rn | head -10
} > "$REPORT"
echo "  Wrote: $REPORT"

# Step 3: Generate CSV
echo "[3/5] Generating CSV..."
{
    echo "metric,value"
    echo "total_requests,$total"
    echo "unique_ips,$(awk '{print $1}' "$LOG" | sort -u | wc -l)"
    awk '{
        codes[$9]++
    } END {
        for (c in codes) print "status_" c "," codes[c]
    }' "$LOG"
} > "$CSV"
echo "  Wrote: $CSV"

# Step 4: Extract top offenders
echo "[4/5] Extracting top offenders..."
awk '{print $1}' "$LOG" | sort | uniq -c | sort -rn | head -5 > "${OUTDIR}/top_ips.txt"
awk '$9 == 404 {print $7}' "$LOG" | sort | uniq -c | sort -rn | head -5 > "${OUTDIR}/top_404.txt"
echo "  Wrote: top_ips.txt, top_404.txt"

# Step 5: Compress anonymized log
echo "[5/5] Compressing..."
gzip -f "$ANON_LOG"
echo "  Compressed: ${ANON_LOG}.gz"

echo ""
echo "=========================================="
echo "  ANALYSIS COMPLETE"
echo "  Report: $REPORT"
echo "  CSV:    $CSV"
echo "=========================================="
```

---

## 14. Deep Understanding

### 14.1 How sed Works (Read → Process → Cycle)

```
sed operates on a cyclic buffer called the PATTERN SPACE.

              +-----------+
  Input ----> | Read line | ----> Pattern Space
              +-----------+          |
                                     |
                              +------v-------+
                              | Execute cmds  |
                              | s/d/p/a/i/c/y |
                              +------+-------+
                                     |
                    +----------------+----------------+
                    |                                 |
              +-----v-----+                    +------v------+
              | -n flag?  |                    | Print space |
              +-----+-----+                    +------+------+
                    | no                              |
                    +---------> Output <--------------+

Then NEXT line is read. Cycle repeats. EOF terminates.

HOLD SPACE: a secondary buffer for storing data across cycles.
Commands: h (copy to hold), H (append), g (copy from hold), G (append from hold), x (swap).
```

### 14.2 How awk Works (Read → Pattern → Action)

```
awk's main loop is implicit:

  1. Initialize: BEGIN block runs once
  2. For each record (line by default):
     a. Split record into fields ($1, $2, ..., $NF)
     b. Evaluate each pattern in order
     c. If pattern matches, execute corresponding action
     d. If no pattern matches, nothing happens (unlike sed)
  3. Finalize: END block runs once

Field splitting uses FS (Field Separator), default whitespace.
$0 = entire record, $1 = first field, $NF = last field.
NR = number of records read, NF = number of fields in current record.
```

### 14.3 Regex Engine (NFA/DFA)

Two types of regex engines:

**DFA (Deterministic Finite Automaton)**
- Used by: `awk`, `egrep` (traditional), `lex`
- Each character processed once — O(n) always
- No backreferences, no lookahead/lookbehind
- Always finds the longest match (leftmost longest)
- Cannot backtrack — faster but less powerful

**NFA (Nondeterministic Finite Automaton)**
- Used by: `sed`, `grep` (GNU), `perl`, `python`, `java`
- Backtracks to try alternatives — potentially O(2^n)
- Supports backreferences, lookahead/lookbehind, lazy quantifiers
- Uses backtracking: tries one path, if fails, goes back and tries another
- Greedy by default (tries longest first), lazy with `?` suffix

**Backreference Performance Impact**
```bash
# Without backreference — NFA, fast
grep -E '([a-z])'  # still uses NFA but no backtrack issue

# With backreference — forces NFA, can cause catastrophic backtracking
grep -E '([a-z]+)-\1'  # \1 must match same text as group

# Catastrophic backtracking example
# Pattern: (a|aa|aaa)*b on string "aaaaaaaaac"
# Each a can match any of the alternatives, creating exponential paths
# Fix: rewrite without nested quantifiers a*b
```

### 14.4 Why `[0-9]` vs `[[:digit:]]`

```bash
[0-9]        # Matches ASCII characters with codes 0x30-0x39
             # Only "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"

[[:digit:]]   # POSIX character class, locale-aware
              # In C locale: same as [0-9]
              # In e.g. ar_SA.utf8: also matches Arabic-Indic digits
              # In e.g. bn_IN: also matches Bengali digits

# When to use which:
# [0-9] — faster, safe for ASCII-only configs, code, logs
# [[:digit:]] — required for internationalized apps, user input validation

# Similarly:
[[:alpha:]] vs [a-zA-Z]   # [[:alpha:]] includes accented chars
[[:space:]] vs [ \t]      # [[:space:]] includes \r, \n, \f, \v
[[:alnum:]] vs [a-zA-Z0-9] # [[:alnum:]] includes locale-specific chars
```

### 14.5 sed vs awk — When to Use Which

| Task | Tool | Reason |
|------|------|--------|
| Simple text substitution | `sed` | Readable one-liner |
| Find lines matching pattern | `grep` | Fastest, simplest |
| Field/column extraction | `awk` | Native field support |
| Arithmetic/computations | `awk` | Full numeric support |
| Complex conditionals | `awk` | C-like syntax |
| Multi-line operations | `sed` (N,D,P) or `awk` | Both work, awk often clearer |
| In-place editing | `sed -i` | Native support |
| Report generation | `awk` | printf, arrays, totals |
| Table joins | `awk` or `join` | Associative arrays |
| Stream transformation | `sed` | Designed for this |

### 14.6 GNU Extensions vs POSIX

Many examples in this course use GNU extensions:

- `sed -i` (in-place) — GNU, not POSIX
- `grep -P` (PCRE) — GNU, not POSIX
- `sort -h` (human sort) — GNU
- `xargs -P` (parallel) — GNU
- `awk` `asorti()` — GNU awk

For maximum portability (BSD/macOS), avoid GNU extensions or test on target.

---

## 15. Command Reference

### Level 1 — Basic

#### 15.1 grep Flags

| Flag | Purpose |
|------|---------|
| `-E` | Extended regex (ERE) |
| `-F` | Fixed string (literal) |
| `-P` | PCRE (Perl-compatible) |
| `-o` | Only matched text |
| `-n` | Line numbers |
| `-c` | Count matches |
| `-l` | List matching files |
| `-L` | List non-matching files |
| `-q` | Quiet (exit code only) |
| `-r` | Recursive |
| `-v` | Invert match |
| `-w` | Whole word match |
| `-i` | Case-insensitive |
| `-x` | Whole line match |
| `-A N` | After context N lines |
| `-B N` | Before context N lines |
| `-C N` | Context N lines each side |
| `-m N` | Max N matches per file |
| `-z` | Null/nul separated records |

#### 15.5 Text Processing Reference

| Tool | Primary Use | Key Feature |
|------|-------------|-------------|
| `grep` | Filter lines by pattern | Fast, recursive, PCRE |
| `sed` | Transform text | In-place, multi-line, hold space |
| `awk` | Process structured text | Fields, arrays, arithmetic |
| `cut` | Extract columns | Fields (by delimiter) or characters |
| `sort` | Sort lines | Numeric, human, key-based |
| `uniq` | Unique/count lines | Adjacent dedup |
| `wc` | Count lines/words/bytes | Fast stats |
| `tr` | Translate/delete chars | Single-char operations |
| `paste` | Merge files horizontally | Side-by-side columns |
| `join` | Relational join | Sorted input, key field |
| `comm` | Compare sorted files | Three-column diff |
| `xargs` | Build command lines | Parallel execution |
| `diff` | Compare files | Unified/context format |
| `patch` | Apply diffs | Reverse, strip path |

### Level 2 — Intermediary

#### 15.2 sed Commands and Flags

| Command | Purpose |
|---------|---------|
| `s/pat/rep/` | Substitute |
| `d` | Delete line |
| `p` | Print line |
| `a text` | Append text after line |
| `i text` | Insert text before line |
| `c text` | Change (replace) line |
| `y/set1/set2/` | Transliterate |
| `q` | Quit after line |
| `r file` | Read file into output |
| `w file` | Write line to file |
| `=` | Print line number |
| `N` | Append next line to pattern space |
| `D` | Delete to first newline |
| `P` | Print to first newline |
| `h/H` | Copy/append to hold space |
| `g/G` | Copy/append from hold space |
| `x` | Exchange hold and pattern spaces |
| `: label` | Label for branch |
| `b label` | Branch (goto) |
| `t label` | Branch if substitution succeeded |

| s/.../.../ Flags | Meaning |
|------------------|---------|
| `g` | Global (all occurrences) |
| `i` | Case-insensitive |
| `p` | Print line if substitution occurred |
| `w file` | Write to file if substitution occurred |
| `e` | Execute result as command (GNU) |
| `N` | Replace Nth occurrence |

#### 15.3 awk Built-in Variables

| Variable | Meaning |
|----------|---------|
| `NR` | Record number (global) |
| `FNR` | Record number (per file) |
| `NF` | Number of fields |
| `$0` | Entire record |
| `$1`..`$N` | Field 1..N |
| `$NF` | Last field |
| `FS` | Field separator (input) |
| `OFS` | Output field separator |
| `RS` | Record separator (input) |
| `ORS` | Output record separator |
| `FILENAME` | Current input file |
| `ARGV` | Command-line arguments array |
| `ARGC` | Argument count |
| `ENVIRON` | Environment variables array |
| `SUBSEP` | Array subscript separator (default: \034) |

#### 15.4 awk Built-in Functions

| Function | Purpose |
|----------|---------|
| `length(s)` | String length |
| `substr(s, i, n)` | Substring |
| `index(s, t)` | Position of t in s |
| `match(s, r)` | Position of regex match |
| `split(s, a, f)` | Split s into array a |
| `gsub(r, t, s)` | Global substitute |
| `sub(r, t, s)` | First substitute |
| `toupper(s)` | Uppercase |
| `tolower(s)` | Lowercase |
| `sprintf(fmt, ...)` | Formatted string |
| `int(x)` | Integer truncation |
| `sqrt(x)` | Square root |
| `rand()` | Random (0-1) |
| `srand(x)` | Seed random |
| `asort(a)` / `asorti(a)` | Sort array (GNU) |
| `system(cmd)` | Execute shell command |
| `strftime(fmt)` | Format timestamp |
| `mktime(ts)` | Make timestamp |
| `systime()` | Current epoch time |

---



## 16. Self-Test

Answer 15 questions. **Score:** 12/15 correct = ready for Part 37.

### Question 1
Which regex flavor does `grep` use by default?
- A) ERE
- B) BRE
- C) PCRE
- D) DFA

### Question 2
What does `sed -n '5,10p'` do?
- A) Deletes lines 5-10
- B) Prints only lines 5-10 to stdout
- C) Prints all lines except 5-10
- D) Substitutes on lines 5-10

### Question 3
In `awk`, what does `$NF` represent?
- A) Number of fields
- B) Last field of current record
- C) First field of next record
- D) Null field

### Question 4
Which `grep` flag enables Perl-compatible regular expressions?
- A) `-E`
- B) `-P`
- C) `-F`
- D) `-G`

### Question 5
What is the hold space in `sed` used for?
- A) Storing the current input line
- B) Storing data across cycles
- C) Buffering output
- D) Holding error messages

### Question 6
Which `xargs` option runs commands in parallel?
- A) `-I`
- B) `-n`
- C) `-P`
- D) `-0`

### Question 7
What does the `BEGIN` block in `awk` do?
- A) Runs after each record
- B) Runs when a pattern matches
- C) Runs before any input is read
- D) Runs at end of file

### Question 8
What is the difference between `[0-9]` and `[[:digit:]]`?
- A) No difference
- B) `[0-9]` is locale-aware; `[[:digit:]]` is ASCII-only
- C) `[[:digit:]]` is locale-aware; `[0-9]` is ASCII-only
- D) `[0-9]` matches letters; `[[:digit:]]` matches digits

### Question 9
Which command creates a patch in unified format?
- A) `patch -u`
- B) `diff -u`
- C) `diff -c`
- D) `patch -c`

### Question 10
In `sed`, what does the `g` flag in `s/old/new/g` mean?
- A) Global (replace all occurrences on line)
- B) Group (capture group)
- C) Greedy match
- D) Generate output

### Question 11
Which tool would you use to efficiently extract the 3rd column from a tab-delimited file?
- A) `sed`
- B) `cut -f3`
- C) `comm`
- D) `paste`

### Question 12
What does `awk '!seen[$0]++'` do?
- A) Counts all lines
- B) Removes duplicate lines (like uniq without requiring sort)
- C) Prints all lines twice
- D) Reverses line order

### Question 13
What is the NFA regex engine behavior when matching `(a|aa)*b` against `aaaaaaaaac`?
- A) Fast linear match
- B) Catastrophic backtracking (exponential)
- C) Immediate failure
- D) Lazy evaluation

### Question 14
Which command shows the difference between two files, ignoring whitespace?
- A) `diff -u`
- B) `diff -w`
- C) `diff -r`
- D) `diff -q`

### Question 15
What does the `-I {}` option in `xargs` do?
- A) Limits arguments per command
- B) Sets the replacement string for substitution
- C) Enables interactive mode
- D) Uses null separators

---

### Answer Key

1. **B** — BRE (Basic Regular Expressions). `grep -E` for ERE, `grep -P` for PCRE.
2. **B** — `-n` suppresses default output; `5,10p` prints lines 5-10. Only those lines appear.
3. **B** — `NF` is the number of fields; `$NF` is the value of the last field.
4. **B** — `-P` enables PCRE. `-E` for ERE, `-F` for fixed strings.
5. **B** — Hold space stores data that persists across the read-process cycle.
6. **C** — `-P N` runs N processes in parallel. `-I` sets replacement string, `-n` sets max args.
7. **C** — `BEGIN` runs once before any input is read. `END` runs after all input.
8. **C** — `[[:digit:]]` is locale-aware and matches digits from various scripts; `[0-9]` is ASCII only.
9. **B** — `diff -u` produces unified format. `patch` applies patches, doesn't create them.
10. **A** — The `g` flag makes the substitution apply to every occurrence on the line, not just the first.
11. **B** — `cut -f3` extracts the 3rd field (tab-delimited by default). Use `-d' '` for other delimiters.
12. **B** — `!seen[$0]++` prints a line only the first time it appears, removing duplicates without sorting.
13. **B** — Nested quantifiers with overlapping alternatives cause catastrophic backtracking.
14. **B** — `diff -w` ignores whitespace differences. `-u` is unified format, `-q` is quiet.
15. **B** — `-I {}` defines `{}` as the replacement string, substituted with each input item.

### Scoring

| Correct | Assessment |
|---------|------------|
| 15/15 | Expert level — you could teach this course |
| 13-14/15 | Strong — ready for Part 37 |
| 12/15 | Pass — ready for Part 37 |
| 10-11/15 | Review weak areas |
| <10/15 | Re-read Part 36 before continuing |

---

*Previous → Part 35: Shell Scripting for System Administrators*
*Next → Part 37: Automation with Ansible*

[← Previous](part35.md) | [Next →](part37.md)
