## 📋 Summary — Complete Command Reference

### Level 1: Basic Commands

**Redirection Operators**

| Operator | Action |
|----------|--------|
| `> file` | Redirect stdout to file (overwrite) |
| `>> file` | Redirect stdout to file (append) |
| `< file` | Redirect stdin from file |

**Pipe**

| Command | Action |
|---------|--------|
| `cmd1 \| cmd2` | Pipe stdout of cmd1 to stdin of cmd2 |
| `cmd1 \| cmd2 \| cmd3` | Chain multiple commands |

**Practical Combinations**

| Pattern | Use |
|---------|-----|
| `cmd > file` | Save output to a file |
| `cmd >> file` | Append output to a file |
| `cmd < file` | Read input from a file |
| `{ cmd1; cmd2; } > file` | Group output of multiple commands |

---

### Level 2: Intermediary Commands

**Redirection Operators**

| Operator | Action |
|----------|--------|
| `2> file` | Redirect stderr to file |
| `2>> file` | Redirect stderr to file (append) |
| `&> file` | Redirect both stdout and stderr |
| `&>> file` | Redirect both (append) |
| `2>&1` | Redirect stderr to where stdout goes |
| `1>&2` | Redirect stdout to where stderr goes |

**Pipe and Tee**

| Command | Action |
|---------|--------|
| `cmd \| tee file` | Send output to both screen and file |
| `cmd \| tee -a file` | Append to file, not overwrite |

**Heredoc and Herestring**

| Syntax | Action |
|--------|--------|
| `cmd << EOF ... EOF` | Send multi-line input to command |
| `cmd << 'EOF' ... EOF` | Heredoc with no variable expansion |
| `cmd <<< "string"` | Send single-line string to stdin |

**Named Pipes**

| Command | Action |
|---------|--------|
| `mkfifo name` | Create a named pipe |
| `rm name` | Remove a named pipe |

**Practical Combinations**

| Pattern | Use |
|---------|-----|
| `cmd 2>/dev/null` | Suppress errors, show normal output |
| `cmd \| tee log` | Watch output live and log it |
| `cmd \| sort \| uniq -c \| sort -rn` | Count and rank occurrences |

---

### Level 3: Advanced Commands

**File Descriptors**

| Command | Action |
|---------|--------|
| `exec 3> file` | Open FD 3 for writing to file |
| `exec 3< file` | Open FD 3 for reading from file |
| `echo text >&3` | Write to FD 3 |
| `exec 3>&-` | Close FD 3 |
| `>&-` | Close a file descriptor |

**Process Substitution**

| Syntax | Action |
|--------|--------|
| `diff <(cmd1) <(cmd2)` | Compare output of two commands |
| `cat <(cmd)` | Use command output as file |

**Practical Combinations**

| Pattern | Use |
|---------|-----|
| `cmd > file 2>&1` | Save all output including errors |
| `cmd > /dev/null 2>&1` | Completely silence a command |

---



---

[← Previous](19-level-3-practices.md) | [↑ Index](index.md) | [Next →](21-whats-coming-in-part-6.md)
