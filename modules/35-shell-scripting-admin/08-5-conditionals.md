## 5. Conditionals

### if/then/elif/else/fi

```bash
#!/bin/bash

if [ "$1" = "start" ]; then
    echo "Starting service..."
elif [ "$1" = "stop" ]; then
    echo "Stopping service..."
elif [ "$1" = "restart" ]; then
    echo "Restarting service..."
else
    echo "Usage: $0 {start|stop|restart}"
    exit 1
fi
```

### The `test` Command (`[ ]`)

```bash
# These are identical:
test "$a" = "$b"
[ "$a" = "$b" ]
```

### String Tests

```bash
[ "$str" = "hello" ]    # Equal (POSIX)
[ "$str" != "hello" ]   # Not equal
[ -z "$str" ]           # Length is zero (empty)
[ -n "$str" ]           # Length is non-zero
```

### Numeric Tests

```bash
[ "$a" -eq "$b" ]   # Equal
[ "$a" -ne "$b" ]   # Not equal
[ "$a" -lt "$b" ]   # Less than
[ "$a" -le "$b" ]   # Less than or equal
[ "$a" -gt "$b" ]   # Greater than
[ "$a" -ge "$b" ]   # Greater than or equal
```

### File Tests

```bash
[ -f "$file" ]    # Is a regular file
[ -d "$dir" ]     # Is a directory
[ -e "$path" ]    # Exists
[ -s "$file" ]    # Not empty (size > 0)
[ -r "$file" ]    # Readable
[ -w "$file" ]    # Writable
[ -x "$file" ]    # Executable
[ -L "$file" ]    # Is a symlink
```

### `[[ ]]` vs `[ ]`

| Feature | `[ ]` (POSIX) | `[[ ]]` (Bash) |
|---|---|---|
| Word splitting | Yes | No |
| Pathname expansion | Yes | No |
| Regex matching | No | `=~` operator |
| Pattern matching | No | `==` with globs |
| Logical operators | `-a`, `-o` | `&&`, `\|\|` |

```bash
# [[ ]] is safer and more powerful
[[ "$str" == "hello" ]]           # No quoting needed
[[ "$str" == h* ]]                # Pattern matching (glob)
[[ "$str" =~ ^[0-9]+$ ]]         # Regex matching
[[ -f "$file" && -r "$file" ]]   # AND with &&
```

### Case Statement

```bash
case "$1" in
    start|begin)
        echo "Starting..."
        ;;
    stop|end)
        echo "Stopping..."
        ;;
    restart)
        echo "Restarting..."
        ;;
    *)
        echo "Unknown option: $1"
        exit 1
        ;;
esac
```





[← Previous](07-4-string-operations.md) | [↑ Index](index.md) | [Next →](09-6-loops.md)
