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





[← Previous](02-level-1-basic-understanding-environment.md) | [↑ Index](index.md) | [Next →](04-section-2-critical-environment-variables.md)
