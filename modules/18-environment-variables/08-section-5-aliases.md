## 🔍 Section 5: Aliases

Aliases are shortcuts for commands.

### Creating Aliases

```bash
# Basic aliases
alias ll='ls -la'
alias la='ls -A'
alias lt='ls -ltr'  # Sorted by time, newest last
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'
alias df='df -h'
alias du='du -ch'
alias free='free -m'
alias cls='clear'

# Dangerous operations with confirmation
alias rm='rm -i'       # Ask before delete
alias cp='cp -i'       # Ask before overwrite
alias mv='mv -i'       # Ask before overwrite
```

### Managing Aliases

```bash
# List all aliases
alias

# List a specific alias
alias ll

# Remove an alias
unalias ll

# Remove all aliases
unalias -a

# Use the original command without alias
\rm file.txt     # Escaping with backslash bypasses alias
command rm file.txt  # Using 'command' also bypasses alias
/bin/rm file.txt     # Full path bypasses alias
```

### Permanent Aliases

```bash
# Add to ~/.bashrc
echo "alias ll='ls -la'" >> ~/.bashrc
source ~/.bashrc
```

---



---

[← Previous](07-section-4-setting-variables.md) | [↑ Index](index.md) | [Next →](09-level-3-advanced-shell-functions.md)
