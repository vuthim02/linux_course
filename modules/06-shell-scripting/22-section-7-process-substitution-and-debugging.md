## 🔍 Section 7: Process Substitution, Subshells, and Debugging

### Process Substitution — `<()` and `>()`

Process substitution feeds the output of a command as a file-like argument.

```bash
# Compare two command outputs without temp files
diff <(ls /etc) <(ls /etc.backup)

# Count unique lines across files
comm -12 <(sort file1.txt) <(sort file2.txt)

# Read from a filtered stream
while read -r line; do
  echo "Processed: $line"
done < <(grep ERROR /var/log/syslog)

# Feed output into a command pipeline
tar -czf >(ssh user@host "cat > backup.tar.gz") /data
```

### Subshells vs Grouping

```bash
# ( ) — creates a subshell (child process)
# Changes inside ( ) don't affect the parent

(cd /tmp && ls)                # Lists /tmp, but stays in original dir
echo "Still in: $(pwd)"        # Original directory

# { } — grouping in the current shell (no subshell)
{ cd /tmp && ls; }             # Lists /tmp AND changes to /tmp!
echo "Now in: $(pwd)"          # /tmp

# Performance: { } is faster — avoids fork()
# Use ( ) only when you need isolation
```

### Background Jobs and Subshells

```bash
# Background with &
long_running_task &

# Wait for all background jobs
wait

# Wait for a specific PID
sleep 5 &
pid=$!
wait "$pid"

# Background in subshell preserves isolation
(result=$(compute_heavy) && echo "$result") &
```

### Debugging Techniques

```bash
# Full trace mode
bash -x script.sh              # Print every command before execution
bash -v script.sh              # Print every line as read (before expansion)

# From within the script
set -x                         # Enable tracing from this point
# ... code to debug ...
set +x                         # Disable tracing

# PS4 — customize the trace prompt
export PS4='+ ${BASH_SOURCE}:${LINENO}: '
set -x

# Debugging with trap
trap 'echo "DEBUG: $LINENO: $BASH_COMMAND"' DEBUG

# Call stack on error
error_trap() {
  local frame=0
  while caller "$frame"; do
    ((frame++))
  done
}
trap 'error_trap' ERR
```

### Useful Debug Variables

```bash
echo "$LINENO"                 # Current line number
echo "$BASH_SOURCE"            # Current script path
echo "$FUNCNAME"               # Current function name (array)
echo "$BASH_LINENO"            # Line numbers in call stack
echo "$BASH_VERSION"           # Bash version string
```



[← Previous](21-section-6-arithmetic-and-expansions.md) | [↑ Index](index.md) | [Next →](23-section-8-security-and-testing.md)
