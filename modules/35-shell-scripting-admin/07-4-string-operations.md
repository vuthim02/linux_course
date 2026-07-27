## 4. String Operations

### Length and Substring

```bash
str="Hello, Linux!"
echo ${#str}   # 13

str="sysadmin"
echo ${str:0:3}   # sys (offset 0, length 3)
echo ${str:3}     # admin (offset 3 to end)
echo ${str: -3}   # min (last 3 chars, space needed)
```

### Pattern Replacement

```bash
file="backup-2025-01-15.tar.gz"
echo ${file/tar.gz/zip}      # backup-2025-01-15.zip
echo ${file//o/O}            # backup-2025-01-15.tar.gz (replace all)

text="foo foo foo"
echo ${text/foo/bar}         # bar foo foo
echo ${text//foo/bar}        # bar bar bar

echo ${file/#backup/snapshot}  # Replace prefix
echo ${file/%.tar.gz/.zip}     # Replace suffix
```

### Case Modification

```bash
name="linux"
echo ${name^^}   # LINUX (uppercase)
echo ${name^}    # Linux (capitalize first)

OS="LINUX"
echo ${OS,,}     # linux (lowercase)
```

### Quoting Rules

```bash
# Single quotes: literal, no expansion
echo 'The $HOME variable is $HOME'

# Double quotes: expansion happens
echo "The $HOME variable is $HOME"

# No quotes: word splitting + glob expansion
echo $PATH                           # Splits on IFS, glob expands

# Best practice: ALWAYS double-quote variable expansions
file="my file.txt"
cat $file       # Fails: tries cat my file.txt
cat "$file"     # Works
```

---



---

[← Previous](06-3-variables.md) | [↑ Index](index.md) | [Next →](08-5-conditionals.md)
