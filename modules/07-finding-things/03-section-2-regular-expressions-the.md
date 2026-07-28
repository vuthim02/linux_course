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





[← Previous](02-section-1-grep-search-file.md) | [↑ Index](index.md) | [Next →](04-section-3-grep-in-practice.md)
