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

### XDG Base Directory Variables

Modern Linux applications follow the XDG Base Directory specification:

| Variable | Purpose | Default |
|----------|---------|---------|
| `XDG_CONFIG_HOME` | User-specific config files | `~/.config` |
| `XDG_DATA_HOME` | User-specific data files | `~/.local/share` |
| `XDG_CACHE_HOME` | User-specific cache files | `~/.cache` |
| `XDG_STATE_HOME` | User-specific state files | `~/.local/state` |
| `XDG_RUNTIME_DIR` | Runtime files (sockets, pipes) | `/run/user/$UID` |

```bash
# Check your XDG variables
printenv | grep XDG

# Common usage:
# ~/.config/ contains: git config, nvim, tmux, etc.
# ~/.local/share/ contains: flatpak, steam, applications
# ~/.cache/ contains: thumbnails, pip cache, browser cache
```

### Proxy and Network Variables

Sysadmins frequently need proxy variables for restricted networks:

| Variable | Purpose |
|----------|---------|
| `http_proxy` | HTTP proxy URL |
| `https_proxy` | HTTPS proxy URL |
| `ftp_proxy` | FTP proxy URL |
| `no_proxy` | Comma-separated domains to exclude |
| `HTTP_PROXY` | Same as http_proxy (uppercase) |

```bash
# Set proxies for a command
http_proxy=http://proxy.example.com:8080 curl https://example.com

# Persistent proxy (add to ~/.bashrc or /etc/profile.d/proxy.sh)
export http_proxy=http://proxy.example.com:8080
export https_proxy=http://proxy.example.com:8080
export no_proxy=localhost,127.0.0.1,.local

# Some programs only read UPPERCASE variants
export HTTP_PROXY="$http_proxy"
export HTTPS_PROXY="$https_proxy"
```

### SSH Environment Variables

When connecting via SSH, these variables are set automatically:

| Variable | Purpose | Example |
|----------|---------|---------|
| `SSH_CONNECTION` | Client and server IPs/ports | `192.168.1.5 45678 10.0.0.1 22` |
| `SSH_CLIENT` | Client IP and port | `192.168.1.5 45678 22` |
| `SSH_TTY` | The TTY assigned by SSH | `/dev/pts/1` |

```bash
# Check if running over SSH
if [ -n "$SSH_CONNECTION" ]; then
    echo "Connected from $(echo $SSH_CONNECTION | awk '{print $1}')"
fi
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
