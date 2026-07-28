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





[← Previous](12-practice-section-15-hands-on-exercises.md) | [↑ Index](index.md) | [Next →](14-summary-command-reference-for-part.md)
