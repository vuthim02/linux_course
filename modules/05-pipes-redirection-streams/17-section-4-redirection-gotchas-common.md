## 🔍 Section 4: Redirection Gotchas — Common Mistakes

### Mistake 1: Wrong Order of 2>&1

```bash
# WRONG — stderr still goes to screen
command 2>&1 > file

# CORRECT — both go to file
command > file 2>&1
```

### Mistake 2: Spaces in Redirects

```bash
# These work (no spaces around >):
command>file
command >file
command > file

# This is WRONG — creates file named "> file" (literally):
command > file  # ← this has TWO spaces after >
# Actually, it's fine in modern bash. But to be safe, don't add extra spaces.
```

### Mistake 3: Forgetting > Destroys Content

```bash
# Accident:
echo "new config" > /etc/nginx/nginx.conf  # OOPS — destroyed original

# Prevention:
# 1. Always use >> unless you want to overwrite
# 2. Back up first: cp file file.bak
# 3. Use set -o noclobber
```

### Mistake 4: Piping to a Command That Doesn't Read stdin

```bash
# This works:
ls | grep foo

# This does NOT work as expected (rm ignores stdin):
find /tmp -name "*.tmp" | rm
# rm needs arguments, not stdin

# Correct way:
find /tmp -name "*.tmp" -delete
# or
find /tmp -name "*.tmp" | xargs rm
# or
rm $(find /tmp -name "*.tmp")
```

### Mistake 5: Not Quoting the Heredoc Delimiter

```bash
# Without quotes, $() and backticks are interpreted:
cat << EOF
The date is $(date)
EOF
# This runs date command and inserts output

# With quotes, everything is literal:
cat << 'EOF'
The date is $(date)
EOF
# This prints "$(date)" literally
```

---



---

[← Previous](16-section-3-file-descriptors-more.md) | [↑ Index](index.md) | [Next →](18-deep-understanding-how-streams-really.md)
