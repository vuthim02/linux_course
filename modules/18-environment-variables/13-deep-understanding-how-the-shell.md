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

### Shell Options with shopt

Bash has runtime options that control behavior. Check and change them with `shopt`:

```bash
# List all shell options
shopt

# Enable/disable an option
shopt -s autocd          # Type directory name to cd into it
shopt -u autocd          # Disable
shopt -s cdspell         # Auto-correct typos in cd
shopt -s checkwinsize    # Check window size after each command
shopt -s histappend      # Append history, don't overwrite
shopt -s dotglob         # Include dotfiles in glob expansion (*)

# Common options for sysadmins:
shopt -s globstar        # ** matches any depth of subdirectories
# Then you can:  ls **/*.log   to find all log files recursively
```

### The `BASH_ENV` and `ENV` Variables

These control startup for non-interactive shells:

```bash
# BASH_ENV (bash-only): file sourced for non-interactive bash shells
export BASH_ENV=~/.bash_env

# ENV (POSIX sh): file sourced for POSIX-mode shells (sh)
export ENV=~/.sh_env
```

When bash runs a script (non-interactive), it checks `$BASH_ENV` and sources that file if set. This is rarely used but important to know for debugging.

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





[← Previous](12-practice-section-15-hands-on-exercises.md) | [↑ Index](index.md) | [Next →](14-summary-command-reference-for-part.md)
