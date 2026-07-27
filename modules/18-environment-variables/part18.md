# 🐧 Linux System Administrator — Complete Course
## Part 18 of ∞: Environment Variables and Shell Configuration

---

> **Reverse Engineering Approach:** Every time you open a terminal, dozens of variables are set before you type a single command. They tell programs where to find executables, what language to speak, which editor to open. When a script breaks mysteriously, it's almost always because an environment variable is missing or wrong. Understanding how your shell starts up and where it gets its configuration is the key to controlling your entire working environment.

---

## 🎯 What You Will Achieve in Part 18

This module is organized into three progressive levels:

| Level | You Will Learn |
|-------|---------------|
| **⭐ Basic** | What environment variables are, how they work, and the critical ones (PATH, HOME, USER, LANG) |
| **⭐ Intermediary** | Shell startup files, setting variables system-wide vs per-user, creating aliases |
| **⭐ Advanced** | Shell functions, customizing the PS1 prompt, debugging environment issues |

---

## ⭐ Level 1: Basic — Understanding Environment Variables

![Environment Variables Diagram](https://upload.wikimedia.org/wikipedia/commons/thumb/3/34/Environment_variables_diagram.svg/800px-Environment_variables_diagram.svg.png)
*Environment variables in a Unix-like operating system, via Wikimedia Commons*

> **Level 1 Goal:** Understand what environment variables are, how they are inherited by child processes, and know the critical variables that control your working environment.

---

## 🔍 Section 1: What Are Environment Variables?

Environment variables are named values that programs read to understand their environment.

```bash
# Every running process has an environment
# The shell's environment is inherited by programs it runs

# View all environment variables
env

# View all variables (including shell-local)
set

# Get the value of a specific variable
echo "$HOME"
echo "$PATH"
echo "$USER"

# Check if a variable exists (returns 1 if not set)
test -v HOME && echo "HOME is set"
```

### How Environment Variables Work

```
Shell (bash) has variables:
    PATH=/usr/bin:/bin
    HOME=/home/alice
    USER=alice
        │
        ▼ (Shell runs a command)
Program (ls)
    Inherits the environment:
    PATH=/usr/bin:/bin
    HOME=/home/alice
    USER=alice

Program can read these with getenv() in C
or via $VARIABLE in shell scripts
```

### Environment vs Shell Variables

```bash
# Shell variable (local to this shell only)
MYVAR="hello"
echo "$MYVAR"         # Works

# But MYVAR is NOT passed to child processes
bash -c 'echo "$MYVAR"'  # Empty!

# Export makes it an environment variable (passed to children)
export MYVAR="hello"
bash -c 'echo "$MYVAR"'  # Shows "hello"
```

---

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

---

## ⭐ Level 2: Intermediary — Configuring Your Shell Environment

![Bash Startup Files Diagram](https://upload.wikimedia.org/wikipedia/commons/thumb/9/9f/Bash_startup_files.svg/800px-Bash_startup_files.svg.png)
*Bash startup file loading order, via Wikimedia Commons*

> **Level 2 Goal:** Configure shell startup files, set environment variables system-wide and per-user, and create aliases for daily efficiency.

---

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

---

## 🔍 Section 4: Setting Variables

### Temporary (Session Only)

```bash
# In the current shell
export MY_VAR="hello"
MY_VAR="hello"  # Without export — only shell-local, not passed to children

# For one command only
MY_VAR="hello" mycommand

# Remove a variable
unset MY_VAR
```

### Per-User Permanent (~/.bash_profile or ~/.profile)

```bash
# Add to ~/.bash_profile
echo 'export EDITOR=nano' >> ~/.bash_profile
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bash_profile

# Apply to current session
source ~/.bash_profile
```

### System-Wide Permanent (/etc/profile or /etc/environment)

```bash
# Method 1: /etc/profile (shell scripts, bash syntax)
echo 'export JAVA_HOME=/usr/lib/jvm/java-11-openjdk' | sudo tee -a /etc/profile

# Method 2: /etc/environment (simple KEY=VALUE format, no export needed)
echo 'JAVA_HOME=/usr/lib/jvm/java-11-openjdk' | sudo tee -a /etc/environment

# Method 3: /etc/profile.d/ script (preferred for packages)
sudo tee /etc/profile.d/java.sh << 'EOF'
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
export PATH="$JAVA_HOME/bin:$PATH"
EOF
sudo chmod +x /etc/profile.d/java.sh
```

---

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

## ⭐ Level 3: Advanced — Shell Functions, Prompt Engineering, and Debugging

![Bash Prompt Customization](https://upload.wikimedia.org/wikipedia/commons/thumb/2/28/Bash_prompt_example.svg/800px-Bash_prompt_example.svg.png)
*Example of a customized Bash prompt, via Wikimedia Commons*

> **Level 3 Goal:** Create reusable shell functions, engineer a custom PS1 prompt, and debug environment variable issues in complex scenarios.

---

## 🔍 Section 6: Shell Functions

Functions are more powerful than aliases — they can accept arguments.

### Simple Functions

```bash
# Define a function (can be in ~/.bashrc or ~/.bash_profile)
mydir() {
    mkdir -p "$1" && cd "$1"
}

# Use it
mydir /tmp/newproject
# Creates directory AND changes into it
```

### Practical Sysadmin Functions

```bash
# Extract any archive regardless of type
extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.gz)  tar -xzf "$1" ;;
            *.tar.bz2) tar -xjf "$1" ;;
            *.tar.xz)  tar -xJf "$1" ;;
            *.zip)     unzip "$1" ;;
            *.rar)     unrar x "$1" ;;
            *.7z)      7z x "$1" ;;
            *)         echo "Unknown archive type" ;;
        esac
    else
        echo "File not found: $1"
    fi
}

# Find large files
findbig() {
    find / -type f -size +"${1:-100}"M -exec ls -lh {} \; 2>/dev/null
}

# Show disk usage by directory
dusort() {
    du -sh "${1:-.}"/* | sort -rh
}

# Backup a file with timestamp
bak() {
    cp "$1" "$1.$(date +%Y%m%d_%H%M%S).bak"
}

# Create a temporary directory and go there
tmpdir() {
    cd "$(mktemp -d)"
}
```

### Listing and Removing Functions

```bash
# List all functions
declare -f

# List function names only
declare -F

# Remove a function
unset -f mydir
```

---

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

---

## 💻 PRACTICE SECTION — 15 Hands-On Exercises

### Level 1 Practices: Environment Basics

---

### ✅ Practice 1: Explore Your Current Environment

```bash
mkdir -p ~/linux-course/part18
cd ~/linux-course/part18

# View all environment variables
env | sort > all_env.txt
echo "Total environment variables: $(wc -l < all_env.txt)"
head -20 all_env.txt

# Check specific important variables
echo ""
echo "=== Important variables ==="
for var in PATH HOME USER SHELL LANG TERM EDITOR PAGER; do
    echo "$var = ${!var:-NOT SET}"
done
```

---

### ✅ Practice 2: PATH Exploration

```bash
cd ~/linux-course/part18

# Show PATH with one directory per line
echo "$PATH" | tr ':' '\n'

# Count directories in PATH
echo ""
echo "Number of PATH entries: $(echo "$PATH" | tr ':' '\n' | wc -l)"

# Find which directory provides common commands
echo ""
echo "=== Command locations ==="
for cmd in ls cp mv cat less grep; do
    which "$cmd"
done
```

---

### Level 2 Practices: Configuration, Startup Files, and Aliases

### ✅ Practice 3: Create and Export Variables

```bash
cd ~/linux-course/part18

# Create a shell variable
MYNAME="Linux Student"
echo "Shell variable: $MYNAME"

# Create a child shell — MYNAME is NOT available
echo "In child shell (without export):"
bash -c 'echo "MYNAME = ${MYNAME:-NOT SET}"'

# Export it
export MYNAME
echo ""
echo "In child shell (after export):"
bash -c 'echo "MYNAME = $MYNAME"'
```

---

### ✅ Practice 4: Set Variable for One Command

```bash
cd ~/linux-course/part18

# Set a variable just for this command
LANGUAGE=fr date

# The variable is NOT set in the current shell
echo "LANGUAGE = ${LANGUAGE:-NOT SET}"

# Set multiple variables
LANG=fr_FR.UTF-8 LC_TIME=fr_FR.UTF-8 date
```

---

### ✅ Practice 5: Explore Shell Startup Files

```bash
cd ~/linux-course/part18

# Check which startup files exist
echo "=== Your startup files ==="
for file in ~/.bash_profile ~/.bash_login ~/.profile ~/.bashrc ~/.bash_logout; do
    if [ -f "$file" ]; then
        echo "EXISTS: $file ($(wc -l < "$file") lines)"
    else
        echo "MISSING: $file"
    fi
done

# Check system-wide files
echo ""
echo "=== System-wide startup files ==="
for file in /etc/profile /etc/bash.bashrc /etc/environment; do
    if [ -f "$file" ]; then
        echo "EXISTS: $file ($(wc -l < "$file") lines)"
    fi
done

# List profile.d scripts
echo ""
echo "=== /etc/profile.d scripts ==="
ls /etc/profile.d/ 2>/dev/null
```

---

### ✅ Practice 6: Read Your .bashrc

```bash
cd ~/linux-course/part18

if [ -f ~/.bashrc ]; then
    echo "=== Your .bashrc ==="
    cat ~/.bashrc
else
    echo ".bashrc does not exist — creating a basic one"
    cat > ~/.bashrc << 'EOF'
# ~/.bashrc: executed by bash for interactive non-login shells

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# Aliases
alias ll='ls -lah'
alias la='ls -A'
alias lt='ls -ltr'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'
alias df='df -h'
alias du='du -ch'
alias free='free -h'

# Prompt
export PS1='\u@\h:\w\$ '

# PATH
export PATH="$HOME/.local/bin:$PATH"
EOF
    echo "Created ~/.bashrc"
fi
```

---

### ✅ Practice 7: Create Useful Aliases

```bash
cd ~/linux-course/part18

# Create temporary aliases
alias ll='ls -la'
alias lt='ls -ltr'
alias dfh='df -h'
alias dus='du -sh *'
alias myip='hostname -I'

# Test them
echo "Testing aliases:"
ll
dfh

# List the new aliases
echo ""
echo "=== Current aliases ==="
alias | grep -E "ll|lt|dfh|dus|myip"

# Unalias
unalias ll lt dfh dus myip
```

---

### Level 3 Practices: Functions, Prompt, Debugging, and Auditing

### ✅ Practice 8: Create Shell Functions

```bash
cd ~/linux-course/part18

# Create a useful function
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Test it
mkcd /tmp/mkcd-test
pwd
cd -

# Create a backup function
bak() {
    cp -r "$1" "${1}_$(date +%Y%m%d_%H%M%S).bak"
}

# Test it
touch /tmp/testfile.txt
bak /tmp/testfile.txt
ls -la /tmp/testfile*

# Create a function with error handling
extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.gz|*.tgz)  tar -xzf "$1" ;;
            *.tar.bz2) tar -xjf "$1" ;;
            *.tar.xz)  tar -xJf "$1" ;;
            *.zip)     unzip "$1" ;;
            *)         echo "Cannot extract: $1 (unknown type)" ;;
        esac
    else
        echo "File not found: $1"
    fi
}

# Clean up
rm -f /tmp/testfile.txt /tmp/testfile*.bak
```

---

### ✅ Practice 9: Customize Your Prompt

```bash
cd ~/linux-course/part18

# Save current prompt
OLD_PS1="$PS1"

# Try different prompts
echo "=== Prompt variations ==="
PS1='[\t] \u@\h:\w\$ '
echo "Try this prompt: PS1='[\t] \u@\h:\w\$ '"

PS1='\u@\h:\n\$ '
echo "Or multi-line: PS1='\u@\h:\n\$ '"

# Restore
PS1="$OLD_PS1"
```

---

### ✅ Practice 10: Environment Inheritance

```bash
cd ~/linux-course/part18

# Demonstrate inheritance
export COURSE_VAR="Part18"

# Run a script
bash -c 'echo "In child: COURSE_VAR=$COURSE_VAR"'

# Subshell also inherits
(
    echo "In subshell: COURSE_VAR=$COURSE_VAR"
)

# Unset and verify
unset COURSE_VAR
bash -c 'echo "After unset: COURSE_VAR=${COURSE_VAR:-NOT SET}"'
```

---

### ✅ Practice 11: Locale Settings

```bash
cd ~/linux-course/part18

# Current locale
echo "Current locale: $LANG"
locale | head -10

# List available locales (first 20)
echo ""
echo "=== Available locales (first 10) ==="
locale -a | head -10

# Try different date formats
echo ""
echo "=== Date in different locales ==="
LANG=en_US.UTF-8 date
LANG=de_DE.UTF-8 date
LANG=fr_FR.UTF-8 date
LANG=ja_JP.UTF-8 date
```

---

### ✅ Practice 12: Add to PATH Temporarily

```bash
cd ~/linux-course/part18

# Create a personal bin directory
mkdir -p ~/bin

# Create a custom script
cat > ~/bin/hello-course << 'EOF'
#!/bin/bash
echo "Hello from PATH! Course: Part 18"
EOF
chmod +x ~/bin/hello-course

# Add to PATH
export PATH="$HOME/bin:$PATH"

# Run it
hello-course

# Check which
which hello-course

# Clean up
rm ~/bin/hello-course
```

---

### ✅ Practice 13: Debug Shell Configuration

```bash
cd ~/linux-course/part18

# Trace what happens when bash starts (login shell)
echo "=== Tracing bash startup ==="
bash -lx -c 'echo "--- Startup complete ---"' 2>&1 | grep -E "Reading|source|\.bash|\.profile|/etc/profile" | head -20 ||
  echo "Would show startup file loading order"

# Check environment size
echo ""
echo "=== Environment size ==="
env | wc -c
echo "bytes"
```

---

### ✅ Practice 14: .bash_logout

```bash
cd ~/linux-course/part18

# Check if .bash_logout exists
if [ -f ~/.bash_logout ]; then
    echo "=== Your .bash_logout ==="
    cat ~/.bash_logout
else
    echo ".bash_logout does not exist"
    echo "This runs when you log out (for cleanup)"
    echo "Example content:"
    cat << 'EOF'
# ~/.bash_logout
# Clear console on logout
clear
# Or: save history
history -a
EOF
fi
```

---

### ✅ Practice 15: Real SysAdmin Scenario — Environment Audit

```bash
cd ~/linux-course/part18

cat > environment_audit.sh << 'EOF'
#!/bin/bash
set -euo pipefail

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
HOSTNAME=$(hostname)
REPORT="environment_audit_report.txt"

echo "============================================" > "$REPORT"
echo "  ENVIRONMENT AUDIT REPORT" >> "$REPORT"
echo "  Hostname: $HOSTNAME" >> "$REPORT"
echo "  Date:     $TIMESTAMP" >> "$REPORT"
echo "============================================" >> "$REPORT"
echo "" >> "$REPORT"

# Section 1: Shell info
echo "1. SHELL INFORMATION" >> "$REPORT"
echo "  Shell: $SHELL" >> "$REPORT"
echo "  Version: $(bash --version | head -1)" >> "$REPORT"
echo "" >> "$REPORT"

# Section 2: PATH analysis
echo "2. PATH ANALYSIS" >> "$REPORT"
echo "  PATH has $(echo "$PATH" | tr ':' '\n' | wc -l) directories" >> "$REPORT"
echo "  PATH length: ${#PATH} characters" >> "$REPORT"
echo "" >> "$REPORT"

# Section 3: Key variables
echo "3. KEY ENVIRONMENT VARIABLES" >> "$REPORT"
for var in HOME USER SHELL LANG TERM EDITOR PAGER DISPLAY TZ; do
    echo "  $var = ${!var:-NOT SET}" >> "$REPORT"
done
echo "" >> "$REPORT"

# Section 4: Startup files status
echo "4. STARTUP FILES STATUS" >> "$REPORT"
for file in /etc/profile ~/.bash_profile ~/.bashrc ~/.profile ~/.bash_logout; do
    if [ -f "$file" ]; then
        echo "  EXISTS: $file ($(wc -l < "$file") lines)" >> "$REPORT"
    else
        echo "  MISSING: $file" >> "$REPORT"
    fi
done
echo "" >> "$REPORT"

# Section 5: Aliases
echo "5. ACTIVE ALIASES" >> "$REPORT"
alias | sed 's/^/  /' >> "$REPORT" || echo "  No aliases" >> "$REPORT"
echo "" >> "$REPORT"

# Section 6: Custom PATH entries
echo "6. CUSTOM PATH ENTRIES" >> "$REPORT"
echo "$PATH" | tr ':' '\n' | grep -E "home|local|private|custom" | sed 's/^/  /' >> "$REPORT" || \
  echo "  No custom PATH entries found" >> "$REPORT"
echo "" >> "$REPORT"

# Section 7: Locale
echo "7. LOCALE SETTINGS" >> "$REPORT"
locale | sed 's/^/  /' >> "$REPORT"
echo "" >> "$REPORT"

echo "============================================" >> "$REPORT"
echo "  END OF REPORT" >> "$REPORT"
echo "============================================" >> "$REPORT"

cat "$REPORT"
EOF

chmod +x environment_audit.sh
./environment_audit.sh
```

---

## 🧠 Deep Understanding — How the Shell Environment Really Works

### Memory Layout of a Process

```
┌─────────────────────────┐  High addresses
│     Environment vars    │  ← env strings (KEY=value\0)
│                         │
│     Command-line args   │  ← argv strings
│                         │
│         Stack           │  ← Local variables, function calls
│           ↓             │
│                         │
│           ↑             │
│         Heap            │  ← Dynamically allocated memory
│                         │
│    Uninitialized data   │  ← BSS section
│                         │
│    Initialized data     │  ← Data section
│                         │
│    Program code (text)  │  ← Executable instructions
└─────────────────────────┘  Low addresses
```

When a program calls `getenv("PATH")`, the C library searches the environment block in the process memory.

### Variable Inheritance Chain

```
Kernel (init) → systemd → login → shell → script → program
Each step INHERITS and CAN ADD to the environment.

systemd sets basic PATH for all users
→ login adds user-specific variables
→ bash adds shell-specific variables
→ script adds its own variables
```

### The `env` Command

```bash
# Run a command with a modified environment
env -i PATH=/usr/bin:/bin HOME=/tmp mycommand
# -i = start with EMPTY environment (ignore current)

# Remove a variable
env -u http_proxy curl https://example.com

# Set and run
env DEBUG=1 myapp

# Print environment sorted
env | sort
```

---

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

## 🚀 What's Coming in Part 19

**Part 19: Software Repositories and PPAs — Package Sources**

You will learn:
- Understanding repository architecture
- Debian/Ubuntu repositories (sources.list, PPAs)
- RPM repositories (yum.repos.d, EPEL, RPM Fusion)
- Adding and managing third-party repositories
- GPG key management for secure repos
- 15 hands-on practices

---

## 📝 Self-Test — Can You Answer These?

1. How do you list all environment variables?
2. What is the difference between `VAR=value` and `export VAR=value`?
3. What does the PATH variable do and how is it searched?
4. Name the four main shell startup files and when each is read.
5. What is the practical difference between `~/.bash_profile` and `~/.bashrc`?
6. What is an alias and how do you create one permanently?
7. How is a shell function different from an alias?
8. What does `PS1` control and give an example with color.
9. How do you add a directory to PATH for the current session?
10. How do you remove an environment variable?
11. How do you run a command with a variable set only for that command?
12. What is the `env -i` command used for?
13. How can a child process access parent's variables?
14. What does `locale -a` show?
15. Where would you add a system-wide environment variable?

**Score:** 12/15 correct = ready for Part 19.

---

*Linux SysAdmin Course | Part 18 of ∞ | Reverse Engineering Approach*
*Previous → Part 17: SELinux and AppArmor*
*Next → Part 19: Software Repositories and PPAs*

[← Previous](part17.md) | [Next →](part19.md)
