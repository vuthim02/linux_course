## 6. Loops

### `for` Loop

```bash
for i in 1 2 3 4 5; do
    echo "Number: $i"
done

# Brace expansion
for i in {1..10}; do
    echo "$i"
done

# With step
for i in {0..20..2}; do
    echo "Even: $i"
done

# C-style
for ((i=0; i<10; i++)); do
    echo "i = $i"
done
```

### Iterating Over Files

```bash
for file in *.txt; do
    echo "Processing: $file"
    wc -l "$file"
done
```

### `while` Loop

```bash
# Read file line by line
while IFS= read -r line; do
    echo "Line: $line"
done < "/var/log/syslog"

# Infinite loop with break
count=0
while true; do
    echo "Iteration $count"
    ((count++))
    [ "$count" -ge 5 ] && break
done
```

### `until` Loop

```bash
until ping -c1 google.com &>/dev/null; do
    echo "Waiting for network..."
    sleep 5
done
echo "Network is up!"
```

### `break` and `continue`

```bash
for i in {1..10}; do
    [ "$i" -eq 5 ] && continue   # Skip 5
    [ "$i" -eq 8 ] && break      # Stop at 8
    echo "$i"
done
# Prints: 1 2 3 4 6 7
```





[← Previous](08-5-conditionals.md) | [↑ Index](index.md) | [Next →](10-level-2-intermediary-functions-error.md)
