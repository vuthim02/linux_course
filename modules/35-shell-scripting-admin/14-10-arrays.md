## 10. Arrays

### Indexed Arrays

```bash
# Declaration
fruits=("apple" "banana" "cherry")
numbers=(1 2 3 4 5)

# Access
echo "${fruits[0]}"    # apple
echo "${fruits[-1]}"   # cherry (last element)

# All elements
echo "${fruits[@]}"    # apple banana cherry

# Length
echo "${#fruits[@]}"   # 3
echo "${#fruits[0]}"   # 5 (length of "apple")

# Append
fruits+=("date")

# Slice
echo "${fruits[@]:1:2}"    # banana cherry

# Iterate
for fruit in "${fruits[@]}"; do
    echo "$fruit"
done

# Remove element
unset "fruits[1]"      # Removes banana
```





[← Previous](13-9-error-handling.md) | [↑ Index](index.md) | [Next →](15-11-parsing-command-line-args.md)
