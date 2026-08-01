## 📏 Rules of Thumb

### The Environment Variable Rules

| Rule | Description | Why |
|------|-------------|-----|
| **Use export** | Make variables available to children | Scripting |
| **Prepend PATH** | For higher priority | Tool selection |
| **Use ${var} syntax** | Cleaner, unambiguous | Readability |
| **Set defaults** | `${var:-default}` | Prevent errors |
| **Check before use** | `[[ -v var ]]` | Safety |

### The Startup File Rules

| File | Use For | Example |
|------|---------|---------|
| `~/.bashrc` | Aliases, functions, prompt | `alias ll='ls -la'` |
| `~/.bash_profile` | Environment vars, PATH | `export PATH=...` |
| `/etc/profile` | System-wide settings | `export EDITOR=vim` |
| `/etc/environment` | System-wide env vars | `PATH=...` |

### The "Command Not Found" Checklist

```bash
# 1. Check PATH:
echo $PATH

# 2. Check if command exists and where:
type command

# 3. Check if in PATH:
which command  # (not always installed — use type instead)

# 4. Add to PATH:
export PATH="/new/path:$PATH"

# 5. Make persistent:
echo 'export PATH="/new/path:$PATH"' >> ~/.bashrc
```

---

**Why these rules matter:** Following these rules prevents shell scripting bugs and helps you understand how programs find their dependencies.

[← Previous](16-self-test-can-you-answer-these.md) | [↑ Index](index.md)
