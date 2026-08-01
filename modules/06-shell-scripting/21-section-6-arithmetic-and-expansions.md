## 🔍 Section 6: Arithmetic, Indirect Expansion, and String Manipulation

### Bash Arithmetic

```bash
# Integer arithmetic with $(( ))
echo $(( 2 + 2 ))               # 4
echo $(( (5 + 3) * 2 ))         # 16
echo $(( 2 ** 10 ))             # 1024 (exponentiation)

# Variables auto-expand inside $(( ))
x=5; y=3
echo $(( x * y ))               # 15 (no $ needed)

# Arithmetic in (( )) — for conditionals
if (( x > y )); then
  echo "$x is greater than $y"
fi

# Increment/decrement
((count++))
((count += 5))
((total = price * quantity))

# The let command (older syntax)
let "result = a + b"
let a++
```

### Base Conversion

```bash
echo $(( 16#FF ))               # 255 (hex to decimal)
echo $(( 8#777 ))               # 511 (octal to decimal)
echo $(( 2#1010 ))              # 10 (binary to decimal)
printf '%x\n' 255               # ff (decimal to hex)
```

### Indirect Expansion

```bash
# ${!var} — use the VALUE of var as the variable name
color_red="#FF0000"
color_blue="#0000FF"
desired="red"
echo "${color_${desired}}"      # ${!var} syntax:
echo "${!desired}"               # Wrong! Use indirect expansion

# Correct indirect expansion:
desired_var="color_red"
echo "${!desired_var}"          # #FF0000

# Namerefs (bash 4.3+): declare -n
declare -n ref=color_red
echo "$ref"                     # #FF0000
ref="#00FF00"                   # Modifies color_red!
echo "$color_red"               # #00FF00
```

### Parameter Expansion — Full Reference

```bash
s="hello world"

# Length
echo "${#s}"                    # 11

# Substring
echo "${s:0:5}"                 # hello
echo "${s:6}"                   # world
echo "${s: -5}"                 # world (space before -5 needed)

# Pattern removal (prefix)
echo "${s#he}"                  # llo world   (remove shortest prefix match)
echo "${s##* }"                 # world       (remove longest prefix match)

# Pattern removal (suffix)
echo "${s%ld}"                  # hello wor   (remove shortest suffix match)
echo "${s%% *}"                 # hello       (remove longest suffix match)

# Search and replace
echo "${s/ll/LL}"               # heLLo world (first match)
echo "${s//l/L}"                # heLLo worLd (all matches)
echo "${s/#he/HE}"              # HEllo world (prefix match)
echo "${s/%ld/LD}"              # hello worLD (suffix match)

# Default values
echo "${var:-default}"          # "default" if var unset/null
echo "${var:=default}"          # assign default if unset, then echo
echo "${var:+alt}"              # "alt" if var is set, empty otherwise
echo "${var:?error}"            # print error and exit if unset

# Case modification (bash 4+)
declare -l low="HELLO"          # "hello" (auto-lowercase)
declare -u up="hello"           # "HELLO" (auto-uppercase)
echo "${s^^}"                   # HELLO WORLD (uppercase all)
echo "${s,,}"                   # hello world (lowercase all)
echo "${s^}"                    # Hello world (capitalize first)
echo "${s,}"                    # hello world (lowercase first)
```



[← Previous](20-self-test-can-you-answer-these.md) | [↑ Index](index.md) | [Next →](22-section-7-process-substitution-and-debugging.md)
