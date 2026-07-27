## 💻 Level 2 Practices

### ✅ Practice 1: Redirect stderr

```bash
cd ~/linux-course/part5

# Run find — notice errors mixed with results
find / -name "hosts" 2>/dev/null

# Send errors to a file
find / -name "hosts" 2> errors.txt

# View errors
cat errors.txt

# Send errors to /dev/null
find / -name "hosts" 2>/dev/null
```

---

### ✅ Practice 2: Separate stdout and stderr

```bash
cd ~/linux-course/part5

# Send normal output to one file, errors to another
find / -name "hosts" > results.txt 2> errors.txt

# Check both
echo "=== Results ==="
wc -l results.txt
echo "=== Errors ==="
wc -l errors.txt
```

---

### ✅ Practice 3: Redirect both streams together

```bash
cd ~/linux-course/part5

# Method 1: traditional
find / -name "hosts" > all.txt 2>&1

# Method 2: bash shorthand
find / -name "hosts" &> all2.txt

# Both files should be identical
diff all.txt all2.txt
```

---

### ✅ Practice 4: tee — See and Save

```bash
cd ~/linux-course/part5

# Run a command and log it simultaneously
ls -la /etc | tee tee_test.txt

# Verify tee_test.txt has the content
head -5 tee_test.txt

# Append mode
echo "New line" | tee -a tee_test.txt

# Practical: log an update
date | tee -a update_log.txt
sudo apt update 2>&1 | tee -a update_log.txt
```

---

### ✅ Practice 5: Create a Named Pipe

```bash
cd ~/linux-course/part5

# Create a named pipe
mkfifo my_pipe
ls -la my_pipe
# Notice the 'p' type

# In a single terminal, both write and read:
echo "Hello through the pipe" > my_pipe &
cat < my_pipe

# Clean up
rm my_pipe
```

---

### ✅ Practice 6: Heredoc

```bash
cd ~/linux-course/part5

# Create a file using heredoc
cat > heredoc_test.txt << EOF
This file was created
using a heredoc redirect
on $(date)
EOF

cat heredoc_test.txt

# Using quoted delimiter (no variable expansion)
cat > literal.txt << 'EOF'
This file contains $HOME literally
The date is $(date) — not expanded
EOF

cat literal.txt
```

---

### ✅ Practice 7: Send Queries With Heredoc

```bash
cd ~/linux-course/part5

# Even without a database, practice the syntax:
cat > query_example.sql << 'SQL'
SELECT * FROM users
WHERE active = 1
ORDER BY created_at DESC;
SQL

cat query_example.sql

# This pattern is used for:
# - Database queries
# - Config file generation
# - Multi-line messages in scripts
```

---

### ✅ Practice 8: Herestring

```bash
cd ~/linux-course/part5

# Count words in a string
wc -w <<< "Count the words in this sentence"

# Transform a string
tr 'a-z' 'A-Z' <<< "make this uppercase"

# Search a string
grep -o '[0-9]\+' <<< "Order 42 has 15 items and costs $99"
```

---

# ⭐ Level 3: Advanced — File Descriptors, exec, and Process Substitution

![Basic Unix pipe buffer structure showing the relationship between read() and write() system calls](https://upload.wikimedia.org/wikipedia/commons/c/c9/Unix_pipe.svg)
*Diagram: Unix pipe buffer structure — kernel buffering between write() and read(). Credit: MrDrBob, CC BY-SA 3.0.*

> **Level 3 Goal:** Master `exec` for shell-wide redirection, use process substitution for advanced command composition, manage custom file descriptors, understand kernel-level stream mechanics, and avoid subtle redirection pitfalls.



---

[← Previous](12-more-pipe-patterns.md) | [↑ Index](index.md) | [Next →](14-section-1-exec-redirecting-streams.md)
