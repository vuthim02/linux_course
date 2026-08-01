## 🔍 Section 4: Arrays — Multiple Values in One Variable

Bash supports two kinds of arrays: **indexed** (numbered positions) and **associative** (string keys, bash 4+).

Indexed arrays can be created implicitly (without `declare`), but associative arrays **require** `declare -A`.

```bash
# Define an indexed array (declare -a is optional)
fruits=("apple" "banana" "cherry" "date")

# Access elements
echo "${fruits[0]}"   # apple
echo "${fruits[1]}"   # banana
echo "${fruits[-1]}"  # date (last element)

# All elements
echo "${fruits[@]}"    # apple banana cherry date
echo "${fruits[*]}"    # Same, but with IFS joining

# Length
echo "${#fruits[@]}"   # 4

# Loop through array
for fruit in "${fruits[@]}"; do
    echo "Fruit: $fruit"
done

# Add elements
fruits+=("elderberry" "fig")

# Slice
echo "${fruits[@]:1:2}"  # banana cherry

# Associative arrays (bash 4+)
declare -A user
user[name]="Alice"
user[age]=30
user[role]="admin"

echo "${user[name]}"   # Alice
```





[← Previous](09-section-3-functions-reusable-code.md) | [↑ Index](index.md) | [Next →](11-section-5-input-and-output.md)
