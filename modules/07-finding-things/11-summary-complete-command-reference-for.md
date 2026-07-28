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





[← Previous](10-deep-understanding-how-search-tools.md) | [↑ Index](index.md) | [Next →](12-whats-coming-in-part-8.md)
