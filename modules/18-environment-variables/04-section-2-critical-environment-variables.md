## 🔍 Section 2: Critical Environment Variables

### The Essential Variables

| Variable | Purpose | Typical Value |
|----------|---------|---------------|
| `PATH` | Where to find executables | `/usr/local/bin:/usr/bin:/bin` |
| `HOME` | Current user's home directory | `/home/alice` |
| `USER` | Current username | `alice` |
| `SHELL` | Current shell path | `/bin/bash` |
| `LANG` | Language and locale | `en_US.UTF-8` |
| `PWD` | Current working directory | `/home/alice/projects` |
| `OLD_PWD` | Previous working directory | `/home/alice` |
| `TERM` | Terminal type | `xterm-256color` or `linux` |
| `EDITOR` | Default text editor | `nano` or `vim` |
| `VISUAL` | Visual editor (GUI) | `code` or `gedit` |
| `PAGER` | Program for paginated output | `less` or `more` |
| `PS1` | Primary prompt string | `\u@\h:\w\$ ` |
| `DISPLAY` | X11 display (GUI) | `:0` or `:1` |
| `TZ` | Timezone | `America/New_York` |
| `LD_LIBRARY_PATH` | Extra library search paths | `/usr/local/lib` |
| `PYTHONPATH` | Extra Python module paths | `/home/alice/.local/lib` |

### PATH — The Most Important Variable

```bash
# PATH tells the shell where to find executables
echo "$PATH"

# PATH is searched in ORDER when you type a command
# First match wins

# Typical PATH:
/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Add a directory to PATH (temporary)
export PATH="$PATH:$HOME/bin"
export PATH="/usr/local/scripts:$PATH"  # Prepend (higher priority)

# Check which executable will be used
which python
type python
```

### Display and Locale Variables

```bash
# LANG — controls language, encoding, sorting
echo "$LANG"
# en_US.UTF-8

# LC_* variables override specific locale categories
# LC_ALL (overrides everything — use with caution)
# LC_MESSAGES (language of messages)
# LC_TIME (date/time format)
# LC_COLLATE (sort order)
# LC_NUMERIC (number format)

# Check all locale settings
locale

# List available locales
locale -a

# Change locale temporarily
export LANG=fr_FR.UTF-8
date          # Shows date in French
export LANG=en_US.UTF-8
```





[← Previous](03-section-1-what-are-environment.md) | [↑ Index](index.md) | [Next →](05-level-2-intermediary-configuring-your.md)
