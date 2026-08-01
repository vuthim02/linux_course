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

### Variable Attributes with `declare` and `readonly`

Every bash variable has **attributes** that control its behavior. You set them with `declare` or `readonly`.

**`readonly`** — makes a variable immutable (cannot be changed or unset):
```bash
readonly PI=3.14159
PI=3                # Error: PI is read-only
unset PI            # Error: PI is read-only
```

**`declare`** — sets attributes on a variable. Inside a function, `declare` also makes the variable **local** (same as `local`).

```bash
declare -i count=5              # Integer: treated as number, not string
declare -r API_KEY="abc123"     # Read-only (same as readonly)
declare -l name="HELLO"         # Auto-lowercase: stores as "hello"
declare -u name="hello"         # Auto-uppercase: stores as "HELLO"
declare -x PATH="/usr/bin"      # Export to environment (like export)
declare -a fruits=("a" "b")     # Indexed array
declare -A user=([k]=v)         # Associative array (bash 4+)
declare -n ref=othervar         # Nameref (reference to another variable)
```

**Scope control with `declare`:**
```bash
myfunc() {
    declare var="local"          # Local to this function
    declare -g global="global"   # Force global scope, even inside a function
}
```

**Inspect attributes with `declare -p`:**
```bash
declare -i count=5
declare -p count       # Prints: declare -i count="5"
```

**Declare without assigning** creates the variable with the attribute but no value:
```bash
declare -i number      # number exists as integer, value defaults to 0
declare -a list        # list exists as empty array
declare -- empty       # Creates empty string variable
```

> 💡 **`declare -f` lists all defined functions.** `declare -F` lists only function names.

**Old `typeset` synonym:** In bash, `typeset` is equivalent to `declare` (exists for ksh compatibility).

**Quick reference:**

| Command | Effect |
|---------|--------|
| `declare -i var=N` | Integer type |
| `declare -r var=N` | Read-only |
| `declare -l var=S` | Auto-lowercase |
| `declare -u var=S` | Auto-uppercase |
| `declare -x var=N` | Export to env |
| `declare -a arr=()` | Indexed array |
| `declare -A map=()` | Associative array |
| `declare -n ref=var` | Nameref |
| `declare -g var=N` | Global scope |
| `declare -p var` | Print attributes |
| `readonly var=N` | Same as `declare -r` |

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
