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



---

[← Previous](08-4-sed-admin-patterns.md) | [↑ Index](index.md) | [Next →](10-6-awk-admin-patterns.md)
