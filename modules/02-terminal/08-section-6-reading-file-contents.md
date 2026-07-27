## 🔍 Section 6: Reading File Contents

### `cat` — Print Entire File

```bash
cat file.txt              # Print file contents
cat -n file.txt           # Print with line numbers
cat file1.txt file2.txt   # Print multiple files in sequence
```

**When NOT to use `cat`:** Never `cat` a large file (log files can be gigabytes). Use `less` instead.

### `less` — Read Large Files Safely

```bash
less /var/log/syslog
```

Navigation inside `less`:

| Key | Action |
|-----|--------|
| `Space` or `f` | Next page |
| `b` | Previous page |
| `g` | Go to beginning |
| `G` | Go to end |
| `/searchterm` | Search forward |
| `?searchterm` | Search backward |
| `n` | Next search result |
| `q` | Quit |

### `head` and `tail` — Read Parts of a File

```bash
head file.txt           # First 10 lines (default)
head -n 25 file.txt     # First 25 lines
head -n 1 file.txt      # Just the first line (great for CSV headers)

tail file.txt           # Last 10 lines
tail -n 50 file.txt     # Last 50 lines
tail -f /var/log/syslog # Follow the file live (new lines appear as written)
```

> 💡 `tail -f` is one of the most used sysadmin commands. When something breaks, you run `tail -f /var/log/syslog` and watch the log update in real time as you try to reproduce the problem.

### `wc` — Count Lines, Words, Characters

```bash
wc file.txt             # Lines, words, characters
wc -l file.txt          # Count lines only
wc -w file.txt          # Count words only
wc -c file.txt          # Count bytes/characters only

# Real use: How many users are on this system?
wc -l /etc/passwd
```

---



---

[← Previous](07-section-5-creating-directories-and.md) | [↑ Index](index.md) | [Next →](09-section-7-copying-moving-and.md)
