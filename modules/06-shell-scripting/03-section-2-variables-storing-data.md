## 🔍 Section 2: Variables — Storing Data

### Defining Variables

```bash
# NO spaces around = !!!
name="Alice"
age=30
current_dir=$(pwd)    # Command substitution
files_count=$(ls | wc -l)

# Using variables
echo "$name"
echo "${name}"        # Same, but safer (needed when text follows the variable)
echo "${name}'s age is $age"
```

### Rules for Variable Names

```bash
# Valid:
NAME="Alice"
name="Alice"
my_name="Alice"
_name="Alice"
NAME2="Alice"

# Invalid:
2name="Alice"      # Starts with number
my-name="Alice"    # Hyphen not allowed
my name="Alice"    # Space not allowed
```

### Quoting Matters

```bash
name="Alice Johnson"

# Double quotes: variables are EXPANDED
echo "Hello, $name"    # Hello, Alice Johnson

# Single quotes: variables are LITERAL
echo 'Hello, $name'    # Hello, $name

# No quotes: works but risky (word splitting, glob expansion)
echo Hello, $name      # Works but can break with special chars
```

> 💡 **Always quote your variables.** Use `"$var"` not `$var`. This prevents word splitting and glob expansion.

### readonly and declare

```bash
readonly PI=3.14159    # Cannot be changed later
declare -i count=5     # Integer type (arithmetic, not string)
declare -r API_KEY="abc123"  # Read-only (same as readonly)
declare -a fruits=("apple" "banana")  # Array
declare -A user=([name]="Alice" [age]=30)  # Associative array (bash 4+)
```

### Variable Expansion Tricks

```bash
name="Alice"

# Default values
echo "${name:-Guest}"       # "Alice" if set, "Guest" if unset/null
echo "${name:+present}"     # "present" if set, empty if unset
echo "${name:?error msg}"   # Print error and exit if unset

# String manipulation
echo "${#name}"             # Length: 5
echo "${name:0:3}"          # Substring: "Ali"
echo "${name/l/L}"          # Replace first l with L: "A lice"
echo "${name//l/L}"         # Replace all l with L: "ALice"

# Default assignment
: "${MY_VAR:=default}"     # Sets MY_VAR to "default" if unset
```





[← Previous](02-section-1-what-is-a.md) | [↑ Index](index.md) | [Next →](04-section-3-conditionals-making-decisions.md)
