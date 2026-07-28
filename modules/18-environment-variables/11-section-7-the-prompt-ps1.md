## 🔍 Section 7: The Prompt (PS1)

Your shell prompt is controlled by the PS1 variable.

### Prompt Special Characters

| Sequence | Displays |
|----------|----------|
| `\u` | Username |
| `\h` | Hostname (short) |
| `\H` | Full hostname |
| `\w` | Current working directory (full) |
| `\W` | Current directory (basename only) |
| `\d` | Date (Mon Jan 15) |
| `\t` | Time (24h HH:MM:SS) |
| `\@` | Time (12h AM/PM) |
| `\$` | `#` for root, `$` for normal user |
| `\n` | Newline |
| `\\` | Backslash |
| `\!` | History number |
| `\#` | Command number |

### Custom Prompt Examples

```bash
# Default Debian/Ubuntu prompt
export PS1='\u@\h:\w\$ '

# With timestamp
export PS1='[\t] \u@\h:\w\$ '

# With colors (root in red, normal in green)
export PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# Multi-line prompt (good for deep directories)
export PS1='\u@\h:\w\n\$ '

# With git branch (if in a git repo)
export PS1='\u@\h:\w$(__git_ps1 "(%s)")\$ '
```

### Prompt Colors

```bash
# Color codes in prompts:
# \033[0;30m  — Black
# \033[0;31m  — Red
# \033[0;32m  — Green
# \033[0;33m  — Yellow
# \033[0;34m  — Blue
# \033[0;35m  — Magenta
# \033[0;36m  — Cyan
# \033[0;37m  — White
# \033[1;32m  — Bold Green
# \033[00m    — Reset

# Always wrap color codes in \[ \] so bash knows they're non-printing
export PS1='\[$(tput bold)\]\[$(tput setaf 2)\]\u@\h\[$(tput sgr0)\]:\w\$ '
```





[← Previous](10-section-6-shell-functions.md) | [↑ Index](index.md) | [Next →](12-practice-section-15-hands-on-exercises.md)
