## 🔍 Section 1: Loops — Doing Things Repeatedly

### for Loop — Iterate Over a List

```bash
# Over explicit list
for fruit in apple banana cherry; do
    echo "Fruit: $fruit"
done

# Over wildcard expansion
for file in /etc/*.conf; do
    echo "Config: $file"
done

# C-style for loop (like C/Java)
for ((i=0; i<10; i++)); do
    echo "Iteration: $i"
done

# Over command output
for user in $(awk -F: '$3 >= 1000 {print $1}' /etc/passwd); do
    echo "User: $user"
done
```

### while Loop — Loop Until Condition Is False

```bash
# Read a file line by line
while IFS= read -r line; do
    echo "Line: $line"
done < /etc/hosts

# Infinite loop with break condition
count=0
while true; do
    echo "Count: $count"
    ((count++))
    [ "$count" -ge 5 ] && break
done

# Watch a process until it finishes
while pgrep -x "apt" > /dev/null; do
    echo "apt is still running..."
    sleep 2
done
echo "apt has finished."
```

### until Loop — Loop Until Condition Is True

```bash
count=0
until [ "$count" -ge 5 ]; do
    echo "Count: $count"
    ((count++))
done
```

### Loop Control

```bash
break       # Exit the loop immediately
continue    # Skip to next iteration
break 2     # Exit 2 levels of nested loops
```

---



---

[← Previous](06-level-1-practices.md) | [↑ Index](index.md) | [Next →](08-section-2-exit-codes-success.md)
