## 16. Command Reference

### Level 1: Basic Bash Builtins

| Command | Description |
|---|---|
| `.` | Source a file |
| `echo` | Output text |
| `exit` | Exit shell |
| `export` | Set environment variable |
| `for` | Loop |
| `if` | Conditional |
| `kill` | Send signal |
| `pwd` | Print working directory |
| `read` | Read from stdin |
| `return` | Return from function |
| `shift` | Shift positional params |
| `source` | Source file |
| `test` / `[` | Test condition |
| `while` | Loop while condition |
| `case` | Conditional branch |

### Level 1: External Scripting Tools

| Command | Description |
|---|---|
| `grep` | Search patterns |
| `cut` | Extract columns |
| `sort` | Sort lines |
| `uniq` | Unique lines |
| `wc` | Word/line/char count |
| `date` | Date/time formatting |
| `bc` | Calculator |

### Level 2: Intermediary Bash Builtins

| Command | Description |
|---|---|
| `function` | Define function |
| `getopts` | Parse options |
| `local` | Local variable |
| `printf` | Formatted print |
| `trap` | Set signal handler |
| `mapfile` | Read lines into array |
| `disown` | Remove job from table |
| `wait` | Wait for background job |
| `select` | Select from menu |
| `set` | Set shell options |

### Level 2: Intermediary External Tools

| Command | Description |
|---|---|
| `awk` | Pattern scanning/processing |
| `sed` | Stream editor |
| `tr` | Translate characters |
| `tee` | Split output (file + stdout) |
| `xargs` | Build and exec command lines |
| `find` | Find files |
| `expr` | Evaluate expression |

### Level 3: Advanced Bash Builtins

| Command | Description |
|---|---|
| `declare` | Declare variable/type |
| `eval` | Evaluate string as command |
| `exec` | Replace shell with command |
| `shopt` | Shell options |
| `typeset` | Declare variable |

### Level 3: Advanced External Tools

| Command | Description |
|---|---|
| `jq` | JSON processor |
| `curl` | HTTP client |
| `rsync` | Sync files |
| `ssh` | Remote shell |

### Script Debugging

```bash
# Debug modes
bash -n script.sh       # Syntax check only (no execution)
bash -x script.sh       # Trace execution (print commands)
bash -v script.sh       # Verbose (print input lines)

# In-script debugging
set -x                  # Enable trace
set +x                  # Disable trace

# PS4 for custom trace prompt
export PS4='+ ${BASH_SOURCE}:${LINENO}: ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
```





[← Previous](19-15-deep-understanding.md) | [↑ Index](index.md) | [Next →](21-14-15-hands-on-practices.md)
