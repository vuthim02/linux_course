## 📋 Summary — Command Reference for Part 18

### Level 1 — Basic Environment Commands

| Command | Action |
|---------|--------|
| `env` | List all environment variables |
| `set` | List all variables (including shell-local) |
| `echo $VAR` | Print value of a variable |
| `export VAR=value` | Set and export variable to child processes |
| `unset VAR` | Remove a variable |

### Level 2 — Intermediary Configuration

| Command | Action |
|---------|--------|
| `env -i CMD` | Run command with empty environment |
| `env -u VAR CMD` | Run command without a specific variable |
| `alias NAME='command'` | Create a temporary alias |
| `unalias NAME` | Remove an alias |
| `declare -p VAR` | Show variable attributes and value |
| `source FILE` | Read and execute commands from a file |
| `. FILE` | Synonym for source |

### Shell Config Files

| File | When Read | Scope |
|------|-----------|-------|
| `/etc/profile` | Login shell | System-wide |
| `/etc/profile.d/*.sh` | Login shell | Per-application |
| `~/.bash_profile` | Login shell | User |
| `~/.bashrc` | Interactive non-login shell | User |
| `~/.bash_logout` | Logout | User |

### Important Environment Variables

| Variable | Purpose |
|----------|---------|
| `PATH` | Command search path (colon-separated) |
| `HOME` | User home directory |
| `USER` | Current username |
| `SHELL` | Path to current shell binary |
| `LANG` | Language/locale settings |
| `TERM` | Terminal type (e.g., xterm-256color) |
| `EDITOR` | Default text editor |
| `PAGER` | Default pager (e.g., less) |
| `PS1` | Primary shell prompt string |

### Level 3 — Advanced Shell Functions and Debugging

| Command | Action |
|---------|--------|
| `function NAME() { COMMANDS; }` | Define a shell function |
| `NAME() { COMMANDS; }` | Shorter function syntax |
| `declare -f NAME` | Display function definition |
| `declare -F` | List function names only |
| `PS1='\u@\h:\w\$ '` | Customize primary prompt |
| `PS2='> '` | Customize continuation prompt |
| `trap 'cmd' SIGNAL` | Execute command on signal |
| `locale -a` | List available locales |
| `localectl set-locale LANG=...` | Set system locale |
| `bash -x SCRIPT` | Debug script execution |
| `set -x` / `set +x` | Enable/disable debug trace in script |
| `strace -e process CMD` | Trace process execution (advanced debug) |

---



---

[← Previous](13-deep-understanding-how-the-shell.md) | [↑ Index](index.md) | [Next →](15-whats-coming-in-part-19.md)
