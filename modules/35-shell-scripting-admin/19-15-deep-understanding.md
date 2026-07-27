## 15. Deep Understanding

### How Bash Executes Scripts

Bash processes a script in **phases**:

```
1. Tokenization: Split input into tokens (words, operators)
2. Parsing: Build AST from tokens (grammar analysis)
3. Expansion: Process ${}, $(), ~, globs, word splitting
4. Quote removal: Remove quote characters
5. Execution: Run the resulting command
```

**Expansion order** (critical for understanding quoting):

```
1. Brace expansion          {a,b,c}
2. Tilde expansion          ~/dir
3. Parameter expansion      $VAR, ${VAR}
4. Command substitution     $(cmd)
5. Arithmetic expansion     $((expr))
6. Word splitting           (splits on IFS)
7. Pathname expansion       *.txt (globbing)
8. Quote removal
```

### Fork/Exec Model

```bash
# When you run any command (including a script):
bash script.sh
```

1. Bash calls `fork()` — creates a copy of the current process (child)
2. Child process calls `execve("/bin/bash", ["bash", "script.sh"], envp)` — replaces child's memory with new program
3. Parent (`wait()`): suspends until child exits
4. Child runs the script, calls `exit()` when done
5. Parent resumes

**Key insight**: `fork()` duplicates everything — file descriptors, environment, variables (but changes in child don't affect parent).

### Subshells vs Current Shell

```bash
# Subshell (runs in child process)
(cd /tmp && ls)   # Parent stays in original directory

# Current shell
cd /tmp && ls     # Parent changes directory too

# More subshell examples:
command1 | command2     # Pipe creates subshells
$(command)              # Command substitution = subshell
{ command; }            # Current shell (no subshell)
```

### Source vs Execute

```bash
# EXECUTE (./script.sh):
# 1. fork() new process
# 2. Kernel reads #!/bin/bash
# 3. execve("/bin/bash", ["./script.sh"])
# 4. Child runs script, child exits
# 5. Parent unaffected

# SOURCE (source script.sh or . script.sh):
# 1. NO fork()
# 2. Bash reads file line by line in CURRENT shell
# 3. All changes (variables, functions, cd) affect current shell
# 4. No exit — just returns
```

### How the Shebang Kernel Handler Works

When you run `./script.sh`:

1. Kernel opens the file, reads first 2 bytes
2. Detects `#!` (0x23 0x21)
3. Reads rest of first line: `/bin/bash`
4. Kernel effectively runs: `/bin/bash ./script.sh`
5. If the interpreter itself has a shebang (e.g., `/usr/bin/env`), kernel follows the chain

**Limits:**
- Maximum shebang length: typically 127-256 bytes (varies by system)
- Only ONE argument can follow the interpreter path
- The shebang path must be absolute (no PATH lookup)

```bash
# What kernel does:
./script.py    # Kernel reads #!/usr/bin/python3
               # Kernel runs: /usr/bin/python3 ./script.py
```

**Why `#!/usr/bin/env bash` is portable:**

```bash
#!/usr/bin/env bash
# Kernel executes: /usr/bin/env bash ./script.sh
# env searches PATH for bash, finds wherever it lives
```

### Associative Arrays (`declare -A`)

```bash
#!/bin/bash

declare -A config
config["host"]="localhost"
config["port"]=5432
config["user"]="admin"

echo "${config[host]}"     # localhost
echo "${!config[@]}"       # host port user

for key in "${!config[@]}"; do
    echo "$key = ${config[$key]}"
done

# Practical: server status map
declare -A servers
servers["web01"]="192.168.1.10"
servers["db01"]="192.168.1.20"

for name in "${!servers[@]}"; do
    ip="${servers[$name]}"
    ping -c1 "$ip" &>/dev/null && echo "$name ($ip): UP" || echo "$name ($ip): DOWN"
done
```

### Removing Elements from Arrays

```bash
arr=(a b c d e)
unset 'arr[2]'                # arr = (a b d e)
arr=("${arr[@]}")             # Re-index

# Remove by value
arr=(a b c d e b f)
remove_value="b"
for i in "${!arr[@]}"; do
    if [ "${arr[$i]}" = "$remove_value" ]; then
        unset 'arr[i]'
    fi
done
arr=("${arr[@]}")
```

---



---

[← Previous](18-12-security-in-scripts.md) | [↑ Index](index.md) | [Next →](20-16-command-reference.md)
