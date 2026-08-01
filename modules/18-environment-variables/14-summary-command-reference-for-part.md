## 📋 Summary — Command Reference for Part 18

### Level 1 — Basic Environment Commands

| Command | Action |
|---------|--------|
| `env` | List all environment variables |
| `printenv` | List environment variables (or specific ones: `printenv PATH HOME`) |
| `set` | List all variables (including shell-local) |
| `echo $VAR` | Print value of a variable |
| `export VAR=value` | Set and export variable to child processes |
| `unset VAR` | Remove a variable |
| `readonly VAR` | Make a variable read-only |
| `set -a` / `set +a` | Enable/disable automatic export of all variables |
| `printf '%q' "$VAR"` | Print variable safely quoted for reuse |
| `cat /proc/PID/environ` | View any process's environment |

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
| `XDG_CONFIG_HOME` | User config files (~/.config) |
| `XDG_DATA_HOME` | User data files (~/.local/share) |
| `XDG_CACHE_HOME` | User cache files (~/.cache) |
| `http_proxy` / `https_proxy` | Proxy URLs for network access |
| `SSH_CONNECTION` | SSH client/server IPs (set by sshd) |
| `DISPLAY` | X11 display (:0) |
| `WAYLAND_DISPLAY` | Wayland display (wayland-0) |

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
| `shopt` | List/modify shell options |
| `shopt -s OPT` | Enable a shell option |
| `declare -r VAR` | Declare a read-only variable |
| `declare -i VAR` | Declare an integer variable |
| `declare -a VAR` | Declare an indexed array |
| `declare -A VAR` | Declare an associative array |
| `declare -l VAR` | Declare auto-lowercase variable |
| `declare -u VAR` | Declare auto-uppercase variable |
| `shopt -s globstar` | Enable recursive glob (** matches all depths) |





[← Previous](13-deep-understanding-how-the-shell.md) | [↑ Index](index.md) | [Next →](15-whats-coming-in-part-19.md)
