## 🧠 Deep Understanding — How Scripts Execute

### The Fork-Exec Process

When you run `./script.sh`, here is exactly what happens:

```
1. Shell reads the shebang line: #!/bin/bash
2. Shell forks a child process
3. Child process executes exec("./script.sh")
4. Kernel sees the shebang line
5. Kernel runs /bin/bash with the script as argument
6. Bash reads the script line by line
7. For each external command, bash forks again
8. Child runs the external command
9. Child exits, parent (bash) continues
10. When all lines done, bash exits
```

### Why Source Is Different

```bash
# Running: creates subshell
./script.sh

# Sourcing: NO subshell
source script.sh
source script.sh
. script.sh      # Same thing
```

When you `source` a script, the commands run in the **current shell**. Variables, directory changes, and function definitions persist after the script ends.

### The Environment

When bash starts a script, it inherits the **environment** but not the shell variables:

```bash
# In terminal:
MYVAR="hello"
export MYEXPORT="world"

# In script:
echo "$MYVAR"      # Empty! Not exported to child
echo "$MYEXPORT"   # "world" — exported variables are passed
```

To pass a variable to a script:

```bash
# Export it
export MYVAR="hello"
./script.sh

# Or set it inline (for that one command only)
MYVAR="hello" ./script.sh
```





[← Previous](15-section-3-scheduling-scripts-with.md) | [↑ Index](index.md) | [Next →](17-level-3-practices.md)
