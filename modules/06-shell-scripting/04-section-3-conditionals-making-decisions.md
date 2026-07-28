## 🔍 Section 3: Conditionals — Making Decisions

### if Statement

```bash
if [ condition ]; then
    echo "Condition is true"
elif [ other_condition ]; then
    echo "Other condition is true"
else
    echo "Neither is true"
fi
```

### The `test` Command and `[ ]`

`[` is actually a command (an alias for `test`). It must have spaces around each argument.

```bash
# Numeric comparisons
[ "$count" -eq 5 ]     # Equal to
[ "$count" -ne 5 ]     # Not equal to
[ "$count" -gt 5 ]     # Greater than
[ "$count" -ge 5 ]     # Greater than or equal
[ "$count" -lt 5 ]     # Less than
[ "$count" -le 5 ]     # Less than or equal

# String comparisons
[ "$name" = "Alice" ]  # Equal to (use single =, not ==)
[ "$name" != "Bob" ]   # Not equal
[ -z "$name" ]         # String is empty (zero length)
[ -n "$name" ]         # String is not empty

# File tests
[ -f "$file" ]         # Is a regular file
[ -d "$dir" ]          # Is a directory
[ -e "$path" ]         # Exists (any type)
[ -r "$file" ]         # Is readable
[ -w "$file" ]         # Is writable
[ -x "$file" ]         # Is executable
[ -s "$file" ]         # Is not empty (size > 0)
[ -L "$file" ]         # Is a symbolic link

# Combining conditions
[ "$a" = "$b" ] && [ "$c" = "$d" ]  # AND
[ "$a" = "$b" ] || [ "$c" = "$d" ]  # OR
[ ! -f "$file" ]                     # NOT
```

### The Modern `[[ ]]` Syntax (Bash-specific, Safer)

```bash
# [[ ]] is a bash keyword, not a command. It's safer and more powerful.

# String patterns with wildcards
[[ "$name" = A* ]]      # true if name starts with "A"
[[ "$name" =~ ^A.*s$ ]] # true if matches regex (starts A, ends s)

# No need to quote variables inside [[ ]]
[[ -f $file ]]           # Works even if file has spaces

# Logical operators are simpler
[[ $a = $b && $c = $d ]]  # AND (single &&)
[[ $a = $b || $c = $d ]]  # OR (single ||)
```

> 💡 **Prefer `[[ ]]` over `[ ]`** in bash scripts. It is faster, safer, and more readable.

### case Statement

```bash
case "$1" in
    start)
        echo "Starting..."
        ;;
    stop)
        echo "Stopping..."
        ;;
    restart|reload)
        echo "Restarting..."
        ;;
    *)
        echo "Usage: $0 {start|stop|restart}"
        exit 1
        ;;
esac
```





[← Previous](03-section-2-variables-storing-data.md) | [↑ Index](index.md) | [Next →](05-section-4-arguments-and-parameters.md)
