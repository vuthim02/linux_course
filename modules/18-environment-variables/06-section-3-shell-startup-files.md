## 🔍 Section 3: Shell Startup Files

This is where confusion arises. Different files are read depending on whether the shell is login, interactive, or non-interactive.

### Login vs Non-Login Shells

| Shell Type | How Started | Config Files Read |
|---|---|---|
| **Login shell** | ssh, tty login, `su -`, `bash --login` | `/etc/profile` → `~/.bash_profile` (or `.bash_login` or `.profile`) |
| **Interactive non-login** | Terminal inside X, `bash` | `~/.bashrc` (after parent shell's config) |
| **Non-interactive** | Script run with `./script.sh` | `$BASH_ENV` (if set) |

### The File Reading Order

```
LOGIN SHELL:
    ┌─────────────────────────────────────┐
    │ /etc/profile                        │  ← System-wide for all users
    │   └── /etc/profile.d/*.sh           │  ← Package-specific
    ├─────────────────────────────────────┤
    │ ~/.bash_profile                     │  ← User-specific (login)
    │   OR ~/.bash_login                  │  ← (if .bash_profile doesn't exist)
    │   OR ~/.profile                     │  ← (if neither exist)
    │     └── ~/.bashrc                   │  ← Usually sourced from here
    └─────────────────────────────────────┘

INTERACTIVE NON-LOGIN SHELL:
    ┌─────────────────────────────────────┐
    │ ~/.bashrc                            │  ← User-specific (interactive)
    │   └── /etc/bash.bashrc              │  ← System-wide bashrc
    │   └── /etc/bash_completion          │  ← If available
    └─────────────────────────────────────┘
```

### What Each File Is For

| File | Scope | Purpose |
|------|-------|---------|
| `/etc/profile` | System-wide | PATH, environment variables, umask |
| `/etc/profile.d/*` | System-wide | Per-application config (lang, vim, etc.) |
| `/etc/bash.bashrc` | System-wide | Bash functions, aliases (not always present) |
| `~/.bash_profile` | Per-user (login) | User-specific environment, exec PATH, start X |
| `~/.bashrc` | Per-user (interactive) | Aliases, functions, prompt, completions |
| `~/.profile` | Per-user (fallback) | Used by other shells (sh, dash) too |
| `~/.bash_logout` | Per-user (logout) | Commands to run on logout |

### The Golden Rule

```bash
# Put ALIASES and FUNCTIONS in ~/.bashrc
# Put ENVIRONMENT VARIABLES in ~/.bash_profile
# Source ~/.bashrc from ~/.bash_profile

# ~/.bash_profile:
if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi

# ~/.bashrc:
alias ll='ls -la'
alias gs='git status'
export EDITOR=nano
```

### Checking Which Files Are Read

```bash
# Add this to each file temporarily to see when they're read
echo "Loading: /etc/profile" | tee -a /tmp/profile-trace

# After opening a new shell:
cat /tmp/profile-trace
```





[← Previous](05-level-2-intermediary-configuring-your.md) | [↑ Index](index.md) | [Next →](07-section-4-setting-variables.md)
