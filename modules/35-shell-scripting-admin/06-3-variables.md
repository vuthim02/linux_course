## 3. Variables

### Basic Assignment

```bash
# NO spaces around =
NAME="Alice"
AGE=30
VERSION=$(uname -r)   # Command substitution
DATE=`date +%Y%m%d`   # Old-style (avoid, use $())
```

### Variable Expansion

```bash
echo $NAME
echo ${NAME}          # Braces for clarity
echo "Hello, ${NAME}" # Always quote!

# Default values
echo ${NAME:-"default"}  # Use default if unset/null
echo ${NAME:="default"}  # Assign default if unset/null
echo ${NAME:?"error msg"} # Error if unset/null
```

### Positional Parameters

```bash
#!/bin/bash
# Save as: args.sh

echo "Script name: $0"
echo "First arg: $1"
echo "Second arg: $2"
echo "All args: $@"
echo "All args (single string): $*"
echo "Number of args: $#"
```

### Special Variables

| Variable | Meaning |
|---|---|
| `$0` | Script name |
| `$1-$9` | Positional arguments |
| `$#` | Number of arguments |
| `$@` | All arguments (each quoted) |
| `$*` | All arguments (single string) |
| `$?` | Exit code of last command |
| `$$` | PID of current script |
| `$!` | PID of last background process |
| `$LINENO` | Current line number in script |





[← Previous](05-2-script-basics.md) | [↑ Index](index.md) | [Next →](07-4-string-operations.md)
