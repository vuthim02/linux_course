# 🐧 Linux System Administrator — Complete Course
## Part 5 of ∞: Pipes, Redirection, and Streams — The Power of Unix

---

> **Reverse Engineering Approach:** Every command you run produces output. Every command can receive input. Most people treat this as invisible magic. We are going to expose the three streams — stdin, stdout, stderr — and learn how to connect programs together like pipes in a plumbing system. Once you understand streams, you can chain simple commands into powerful data-processing pipelines.

---

## 🎯 What You Will Achieve in Part 5

| Level | What You Will Master |
|-------|---------------------|
| ⭐ **Level 1: Basic** | Understand stdin, stdout, and stderr — what they are and where they go. Redirect output to files (overwrite and append). Redirect input from files. Use pipes to chain commands into powerful data pipelines. |
| ⭐ **Level 2: Intermediary** | Redirect errors separately from normal output. Combine multiple streams into one. Use `tee` to see output AND save it simultaneously. Understand named pipes (FIFOs) for inter-process communication. Use heredocs and herestrings for multi-line input. |
| ⭐ **Level 3: Advanced** | Use `exec` to redirect streams for the entire shell. Master process substitution `<()` and `>()`. Create custom file descriptors beyond 0/1/2. Understand how streams work in the kernel. Build professional system reports with advanced redirection. |

---

# ⭐ Level 1: Basic — Understanding the Three Streams

![POSIX pipeline of standard streams showing terminal, stdin, stdout, stderr between two programs](https://upload.wikimedia.org/wikipedia/commons/f/f6/Pipeline.svg)
*Diagram: POSIX pipeline of standard streams. Credit: XcepticZP / TuukkaH, Public Domain.*

> **Level 1 Goal:** Understand stdin, stdout, stderr, basic redirection (`>`, `>>`, `<`), and pipes (`|`) to chain simple commands into data-processing pipelines.

## 🔍 Section 1: The Three Streams — stdin, stdout, stderr

Every Linux program starts with three open streams:

```
┌─────────────────────┐
│                     │
│     PROGRAM         │
│                     │
│  stdin  (0)  ◄──────┼───── Keyboard (by default)
│  stdout (1)  ──────►├───── Terminal screen (by default)
│  stderr (2)  ──────►├───── Terminal screen (by default)
│                     │
└─────────────────────┘
```

| Stream | Number | Default | Purpose |
|--------|--------|---------|---------|
| **stdin** | 0 | Keyboard | Input to the program |
| **stdout** | 1 | Screen | Normal output from the program |
| **stderr** | 2 | Screen | Error messages from the program |

### The Key Insight

stdout and stderr both go to the screen by default. **This is why errors and normal output appear together.** Separating them is one of the most powerful things a sysadmin can do.

### Identifying Streams in Practice

```bash
# This command produces both normal output and errors:
find / -name "hosts"
# Normal output: paths to files named "hosts"
# Error output: "Permission denied" messages

# Both look the same on screen. But they come from different streams.
```

---

## 🔍 Section 2: Redirecting stdout — The `>` Operator

Send stdout to a file instead of the screen:

```bash
# Save directory listing to a file
ls -la /etc > etc_listing.txt

# Create a file with content
echo "Hello, Linux" > greeting.txt

# Overwrite vs Append:
>   # Overwrite — destroys existing content
>>  # Append — adds to existing content
```

### The Danger of `>`

```bash
# THIS WILL DESTROY YOUR FILE:
echo "new content" > important_config.txt

# Always think: "Am I sure I want to overwrite?"
# Use >> if you want to add, not replace.

# Safety tip:
set -o noclobber   # Prevents accidental overwrite with >
# Now: > will fail if file exists
# Use >| to force override
```

### Real Examples

```bash
# Save running processes to a file
ps aux > running_processes.txt

# Save disk usage report
df -h > disk_report.txt

# Save kernel messages
dmesg > boot_messages.txt

# Append new log entry to an existing file
echo "$(date): System rebooted" >> /var/log/reboot_history.log
```

---

## 🔍 Section 3: Redirecting stdin — The `<` Operator

Read input from a file instead of the keyboard.

```bash
# Count words in a file
wc -w < myfile.txt

# Sort lines from a file
sort < unsorted.txt

# Count lines in a file
wc -l < /etc/passwd
```

### When Would You Use `<`?

Most commands accept a filename as an argument:

```bash
# These do the same thing:
wc -l /etc/passwd
wc -l < /etc/passwd
```

But stdin redirection becomes powerful in pipelines (which we cover next). And some programs only read from stdin:

```bash
# Some commands only read from stdin (they don't accept filename arguments)
tr ',' '\n' < data.csv
# tr (translate) does not take a filename — you must redirect

mail -s "Subject" user@example.com < report.txt
# mail command reads the message body from stdin
```

---

## 🔍 Section 4: Pipes — The Heart of Unix Philosophy

The pipe `|` connects stdout of one command to stdin of another.

```bash
command1 | command2
```

```
┌──────────┐    stdout     ┌──────────┐
│ command1 │──────────────►│ command2 │
└──────────┘               └──────────┘
```

### Simple Examples

```bash
# List files, then filter for "hosts"
ls /etc | grep hosts

# Count processes owned by root
ps aux | grep root | wc -l

# See the largest files in /var/log
ls -lS /var/log | head -5

# Show disk usage sorted by size
df -h | sort -k5 -n
```

### The Unix Philosophy in One Sentence

> **"Do one thing and do it well, then chain them together."**

Each command does one job:
- `ls` — lists files
- `grep` — filters lines
- `sort` — sorts lines
- `wc` — counts lines
- `head` — shows first lines

Chained together, they solve complex problems.

### Building a Pipeline Step by Step

```bash
# Problem: Find the 5 largest files in /var/log

# Step 1: List files with sizes
ls -l /var/log
# Result: -rw-r--r-- 1 root root 12345 Jan 15 10:30 syslog

# Step 2: Sort by file size (5th field) numerically
ls -l /var/log | sort -k5 -n

# Step 3: Take the last 5 (largest)
ls -l /var/log | sort -k5 -n | tail -5

# Step 4: Keep only the filename (last field)
ls -l /var/log | sort -k5 -n | tail -5 | awk '{print $NF}'
```

### Even More Powerful Pipelines

```bash
# How many unique users are running processes?
ps aux | awk '{print $1}' | sort | uniq | wc -l

# What are the top 5 commands in your history?
history | awk '{print $2}' | sort | uniq -c | sort -rn | head -5

# Find all listening ports and their programs
ss -tlnp | awk 'NR>1 {print $4, $7}' | sort

# Show disk usage of top-level directories
du -sh /* 2>/dev/null | sort -rh | head -10
```

---

## 🔍 Common Pipe Patterns Every SysAdmin Should Know

### Pattern 1: Find and Count

```bash
# Count total files
find /etc -type f | wc -l

# Count lines containing "error" in logs
grep -r "ERROR" /var/log/ | wc -l
```

### Pattern 5: Unique IPs From Access Log

```bash
grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" /var/log/nginx/access.log | sort -u | wc -l
```

### Pattern 7: Create a Report

```bash
{
  echo "=== System Report $(date) ==="
  echo "--- Disk Usage ---"
  df -h
  echo "--- Memory ---"
  free -h
  echo "--- Uptime ---"
  uptime
  echo "--- Running Services ---"
  systemctl list-units --type=service --state=running
} > system_report.txt
```

### Pattern 8: Pipe Output to a Pager

```bash
# When output is very long
dmesg | less
journalctl -xe | less
ps aux | less

# Search within output interactively
dmesg | grep "error" | less
```

---

## 💻 Level 1 Practices

### ✅ Practice 1: Redirect stdout

```bash
cd ~/linux-course/part5
mkdir -p ~/linux-course/part5

# List files and save to a file
ls -la /etc > etc_list.txt

# View the file
cat etc_list.txt

# Append more data
echo "---END OF LIST---" >> etc_list.txt

# Verify
tail -5 etc_list.txt
```

---

### ✅ Practice 2: Pipe Basics

```bash
# Filter ls output
ls /etc | grep "conf"

# Chain three commands
ls /etc | grep "conf" | wc -l

# How many conf files are in /etc?
echo "Number of .conf files in /etc: $(ls /etc | grep '\.conf' | wc -l)"
```

---

### ✅ Practice 3: Build a Pipeline Step by Step

```bash
cd ~/linux-course/part5

# Problem: What are the 10 most common words in your bash history?
# Step 1: Get history
history > my_history.txt

# Step 2: Extract just the commands (second column)
awk '{print $2}' my_history.txt > commands.txt

# Step 3: Sort them
sort commands.txt > sorted_commands.txt

# Step 4: Count unique occurrences
uniq -c sorted_commands.txt > counted_commands.txt

# Step 5: Sort by frequency (reverse numeric)
sort -rn counted_commands.txt > frequency.txt

# Step 6: Top 10
head -10 frequency.txt

# OR all in one pipeline:
history | awk '{print $2}' | sort | uniq -c | sort -rn | head -10
```

---

### ✅ Practice 4: Redirect stdin From a File

```bash
cd ~/linux-course/part5

# Create a data file
echo -e "banana\napple\ncherry\ndate" > fruits.txt

# Sort with stdin redirect
sort < fruits.txt

# Count lines
wc -l < fruits.txt

# Compare: many commands accept both
sort fruits.txt          # argument
sort < fruits.txt        # stdin redirect
# Same result
```

---

# ⭐ Level 2: Intermediary — Error Handling and Advanced Redirection

![Schema of POSIX and C standard streams showing terminal, process, stdin, stdout, stderr](https://upload.wikimedia.org/wikipedia/commons/7/70/Stdstreams-notitle.svg)
*Diagram: Standard streams (stdin, stdout, stderr) between terminal and process. Credit: Danielpr85 / TuukkaH, Public Domain.*

> **Level 2 Goal:** Master stderr redirection, combine streams, use `tee` for simultaneous viewing and logging, create named pipes for IPC, and write multi-line input with heredocs and herestrings.

## 🔍 Section 1: Redirecting stderr — The `2>` Operator

Errors and normal output are separate. You can redirect them independently.

```bash
# Send errors to a file, normal output stays on screen
find / -name "hosts" 2> errors.txt

# Send errors to /dev/null (the bit bucket — discard them)
find / -name "hosts" 2> /dev/null

# Send both stdout and stderr to different files
find / -name "hosts" > results.txt 2> errors.txt
```

### /dev/null — The Black Hole

```bash
# Discard ALL output
command > /dev/null 2>&1

# Discard only errors
command 2> /dev/null

# Discard only normal output
command > /dev/null
```

> 💡 `/dev/null` is a special device file. Whatever you write to it disappears forever. Whatever you read from it returns nothing (EOF immediately).

### Redirecting Both Streams to the Same File

```bash
# Method 1: Redirect stderr to stdout, then stdout to file
find / -name "hosts" > all_output.txt 2>&1

# Method 2: Bash shorthand (cleaner)
find / -name "hosts" &> all_output.txt

# Method 3: Append both
find / -name "hosts" &>> all_output.txt
```

### Understanding `2>&1`

Read it right to left:

```
> file     → Send stdout to "file"
2>&1       → Send stderr (2) to where stdout (1) is going

So:  > file 2>&1
     means: stdout goes to file, stderr follows stdout to file
```

Order matters:

```bash
# CORRECT: stdout to file, then stderr to stdout's location
command > file 2>&1

# WRONG: stderr goes to stdout's location (still the screen),
#        then stdout goes to file
command 2>&1 > file
# Result: stderr goes to screen, stdout goes to file (not what you wanted)
```

---

## 🔍 Section 2: tee — Split Output to Screen AND File

`tee` splits a stream: one copy goes to a file, another continues to stdout.

```bash
command | tee output.txt
```

```
                    ┌──────────────► Screen
                    │
┌──────────┐    ┌───┴────┐
│ command  │───►│  tee   │
└──────────┘    └───┬────┘
                    │
                    └──────────────► file.txt
```

### Real Uses

```bash
# See the output AND save it
ls -la /etc | tee etc_listing.txt

# Append to file (don't overwrite)
ls -la /etc | tee -a etc_listing.txt

# Capture errors too
find / -name "hosts" 2>&1 | tee full_search.txt

# Log a command while watching it live
sudo apt update 2>&1 | tee apt_update_$(date +%Y%m%d).log
```

> 💡 `tee` is invaluable during maintenance. Run a command, watch it live, AND have a log file for later debugging.

---

## 🔍 Section 3: Named Pipes (FIFOs) — Connect Processes Without Files

A **named pipe** (also called a FIFO — First In, First Out) is a special file that connects two processes. Data written to one end is read from the other.

```bash
# Create a named pipe
mkfifo mypipe

# Verify
ls -la mypipe
# prw-r--r-- 1 alice alice 0 Jan 15 10:30 mypipe
# The 'p' means it's a pipe
```

### How It Works

```bash
# Terminal 1: Write to the pipe
echo "Hello through pipe" > mypipe
# This BLOCKS until someone reads from the pipe

# Terminal 2: Read from the pipe
cat < mypipe
# "Hello through pipe" appears
# Both commands then complete
```

### Real Use Case — Server Log Monitoring

```bash
# Create a named pipe for log monitoring
mkfifo /tmp/logpipe

# Terminal 1: Write logs to the pipe
tail -f /var/log/syslog > /tmp/logpipe

# Terminal 2: Read and process logs in real time
cat /tmp/logpipe | grep "ERROR" | tee errors.log
```

### Unnamed Pipes vs Named Pipes

| Aspect | Unnamed Pipe (`\|`) | Named Pipe (`mkfifo`) |
|--------|---------------------|----------------------|
| Persistence | Exists only while commands run | Exists as a file until removed |
| Connection | Connects two running commands | Can connect commands at different times |
| Scope | Current shell session | Any process on the system |

---

## 🔍 Section 4: Heredocs and Herestrings — Redirecting Multi-line Input

### Heredoc — Send Multiple Lines to stdin

```bash
# Syntax: command << DELIMITER
#         ...lines...
#         DELIMITER

cat << EOF
This is a multi-line
block of text
that goes to cat's stdin
EOF
```

### Real Heredoc Uses

```bash
# Create a file with multi-line content
cat > ~/deploy.sh << 'EOF'
#!/bin/bash
echo "Starting deployment..."
rsync -avz ./dist/ user@server:/var/www/
echo "Deployment complete."
EOF

# Send SQL query to database (without heredoc would be painful)
mysql -u root -p << SQL
CREATE DATABASE myapp;
USE myapp;
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100)
);
SQL

# Write a config file programmatically
sudo tee /etc/nginx/sites-available/myapp << EOF
server {
    listen 80;
    server_name example.com;
    root /var/www/myapp;
    index index.html;
}
EOF
```

### Quoted vs Unquoted Delimiter

```bash
# WITH quotes: variables are NOT expanded
cat << 'EOF'
$HOME is not expanded
$(date) stays as-is
EOF

# WITHOUT quotes: variables ARE expanded
cat << EOF
$HOME is expanded
$(date) shows current date
EOF
```

### Herestring — Single Line to stdin

```bash
# Syntax: command <<< "string"

# Count words in a string
wc -w <<< "Hello world from herestring"

# Search a string with grep
grep "error" <<< "Everything is fine, no error here"

# Pass string to a command that reads stdin
tr '[:lower:]' '[:upper:]' <<< "make this uppercase"
```

---

## 🔍 More Pipe Patterns

### Pattern 2: Find Largest Files

```bash
find / -type f -size +100M 2>/dev/null | xargs ls -lhS 2>/dev/null | head -10
```

### Pattern 3: Top CPU-Consuming Processes

```bash
ps aux --sort=-%cpu | head -6
```

### Pattern 4: Most Frequent Commands in History

```bash
history | awk '{print $2}' | sort | uniq -c | sort -rn | head -10
```

### Pattern 6: Monitor Logs in Real Time

```bash
tail -f /var/log/syslog | grep --line-buffered "ERROR" | tee /tmp/errors.log
```

---

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

## 🔍 Section 1: exec — Redirecting Streams for the Entire Shell

The `exec` command can redirect streams for the **current shell**, not just a single command.

```bash
# Redirect all stdout of this shell session to a file
exec > session.log

# Now every command's output goes to the file
ls -la          # Goes to session.log
date            # Goes to session.log
echo "Done"     # Goes to session.log

# Restore stdout by saving it first
exec 3>&1       # Save original stdout to FD 3
exec > session.log
echo "This goes to the log file"
exec >&3        # Restore stdout from FD 3
echo "This goes back to the screen"
```

### Real Use Case — Logging an Entire Script

```bash
#!/bin/bash
# At the top of your script:
exec 2>&1        # Send stderr to stdout
exec > >(tee -a script.log)   # Send stdout to both screen and log

# Now ALL output (including errors) goes to the log AND screen
echo "Script started at $(date)"
ls /nonexistent  # This error will be logged too
echo "Script finished"
```

---

## 🔍 Section 2: Process Substitution — `<()` and `>()`

Process substitution lets you use the output of a command as if it were a file.

```bash
# Compare output of two commands
diff <(ls /etc) <(ls /etc/default)

# Count lines matching a pattern from two different sources
cat <(grep -c "error" log1.txt) <(grep -c "error" log2.txt)

# Use command output where only filenames are accepted
wc -l <(find /etc -name "*.conf" 2>/dev/null)
```

### Real Example — Compare Two Directories

```bash
# List files in two directories and diff them
diff <(ls -la /etc) <(ls -la /etc/default)
```

---

## 🔍 Section 3: File Descriptors — More Than Just 0, 1, 2

Linux allows more than just 0/1/2. You can create custom file descriptors.

```bash
# Open file descriptor 3 for writing to a file
exec 3> custom_output.txt

# Write to it
echo "This goes to FD 3" >&3
echo "This also goes to FD 3" >&3

# Close it
exec 3>&-
```

### Practical Example — Log to Multiple Files

```bash
# Create two log channels
exec 3> debug.log
exec 4> error.log

# Use them
echo "Debug: starting process" >&3
echo "Error: something failed" >&4
echo "Normal: continuing"       # Goes to stdout

# Close when done
exec 3>&-
exec 4>&-
```

---

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

## 🧠 Deep Understanding — How Streams Really Work

### Every File Is a Stream

Remember "everything is a file" from Part 1? stdin, stdout, stderr are **file descriptors** — numbers that point to open files.

```bash
# See the file descriptors of your current shell
ls -la /proc/$$/fd
# lrwx------ 1 alice alice 64 Jan 15 10:30 0 -> /dev/pts/0
# lrwx------ 1 alice alice 64 Jan 15 10:30 1 -> /dev/pts/0
# lrwx------ 1 alice alice 64 Jan 15 10:30 2 -> /dev/pts/0

# All three point to your terminal device
```

When you redirect:

```bash
ls > file.txt 2>&1
# Before:  1 -> /dev/pts/0, 2 -> /dev/pts/0
# After:   1 -> /path/to/file.txt, 2 -> /path/to/file.txt
# The redirect just changes where the file descriptor points
```

### What Happens in the Kernel

```
1. Shell forks a child process for the command
2. Before exec'ing the command, shell rearranges file descriptors:
   - Opens the target file
   - Uses dup2() to copy the file descriptor to 1 (stdout)
   - Closes the original fd
3. Child process inherits the modified file descriptors
4. Command writes to stdout — it goes to the file without knowing
```

### Why Pipes Are More Efficient Than Temporary Files

```bash
# Without pipe (uses disk):
ls > /tmp/temp.txt
wc -l < /tmp/temp.txt
rm /tmp/temp.txt

# With pipe (stays in memory):
ls | wc -l
```

The pipe buffer lives in kernel memory, not on disk. For large data, pipes avoid disk I/O entirely.

### The Pipe Buffer Size

```bash
# The pipe buffer is typically 64KB on Linux
# When a pipe is full, the writer blocks
# When a pipe is empty, the reader blocks
# This is automatic flow control

# Check pipe size:
ulimit -a | grep pipe
# pipe size            (512 bytes, -p) 8
# This means 8 * 512 = 4096 bytes default pipe size
```

---

## 💻 Level 3 Practices

### ✅ Practice 1: Process Substitution

```bash
cd ~/linux-course/part5

# Compare two directory listings
diff <(ls /etc) <(ls /etc/default)

# Count files matching pattern in two locations
echo "Confs in /etc: $(ls /etc/*.conf 2>/dev/null | wc -l)"
echo "Confs in /etc/nginx: $(ls /etc/nginx/*.conf 2>/dev/null | wc -l)"

# Use diff on command outputs
diff <(ps aux | sort) <(ps aux | sort)  # Should show no difference
```

---

### ✅ Practice 2: File Descriptors

```bash
cd ~/linux-course/part5

# Create custom file descriptors
exec 3> fd3_output.txt
exec 4> fd4_output.txt

# Write to them
echo "Message for FD 3" >&3
echo "Message for FD 4" >&4
echo "Normal stdout message"

# Close them
exec 3>&-
exec 4>&-

# Verify
cat fd3_output.txt
cat fd4_output.txt
```

---

### ✅ Practice 3: Real SysAdmin Scenario — Build a System Report

```bash
cd ~/linux-course/part5

# Build a comprehensive system report using redirection
{
  echo "========================================"
  echo "  SYSTEM REPORT - $(date)"
  echo "  Hostname: $(hostname)"
  echo "  User: $(whoami)"
  echo "========================================"
  echo ""
  echo "--- UPTIME ---"
  uptime
  echo ""
  echo "--- DISK USAGE ---"
  df -h
  echo ""
  echo "--- MEMORY ---"
  free -h
  echo ""
  echo "--- RUNNING PROCESSES (top 10 by CPU) ---"
  ps aux --sort=-%cpu | head -11
  echo ""
  echo "--- OPEN PORTS ---"
  ss -tlnp 2>/dev/null
  echo ""
  echo "--- LAST 5 LOGIN ATTEMPTS ---"
  last -5 2>/dev/null || echo "No login records"
  echo ""
  echo "========================================"
  echo "  END OF REPORT"
  echo "========================================"
} > system_report_$(date +%Y%m%d).txt 2>&1

# View the report
less system_report_*.txt

# Or email it (if mail command is available):
# mail -s "System Report $(hostname) $(date)" admin@example.com < system_report_*.txt
```

---

## 📋 Summary — Complete Command Reference

### Level 1: Basic Commands

**Redirection Operators**

| Operator | Action |
|----------|--------|
| `> file` | Redirect stdout to file (overwrite) |
| `>> file` | Redirect stdout to file (append) |
| `< file` | Redirect stdin from file |

**Pipe**

| Command | Action |
|---------|--------|
| `cmd1 \| cmd2` | Pipe stdout of cmd1 to stdin of cmd2 |
| `cmd1 \| cmd2 \| cmd3` | Chain multiple commands |

**Practical Combinations**

| Pattern | Use |
|---------|-----|
| `cmd > file` | Save output to a file |
| `cmd >> file` | Append output to a file |
| `cmd < file` | Read input from a file |
| `{ cmd1; cmd2; } > file` | Group output of multiple commands |

---

### Level 2: Intermediary Commands

**Redirection Operators**

| Operator | Action |
|----------|--------|
| `2> file` | Redirect stderr to file |
| `2>> file` | Redirect stderr to file (append) |
| `&> file` | Redirect both stdout and stderr |
| `&>> file` | Redirect both (append) |
| `2>&1` | Redirect stderr to where stdout goes |
| `1>&2` | Redirect stdout to where stderr goes |

**Pipe and Tee**

| Command | Action |
|---------|--------|
| `cmd \| tee file` | Send output to both screen and file |
| `cmd \| tee -a file` | Append to file, not overwrite |

**Heredoc and Herestring**

| Syntax | Action |
|--------|--------|
| `cmd << EOF ... EOF` | Send multi-line input to command |
| `cmd << 'EOF' ... EOF` | Heredoc with no variable expansion |
| `cmd <<< "string"` | Send single-line string to stdin |

**Named Pipes**

| Command | Action |
|---------|--------|
| `mkfifo name` | Create a named pipe |
| `rm name` | Remove a named pipe |

**Practical Combinations**

| Pattern | Use |
|---------|-----|
| `cmd 2>/dev/null` | Suppress errors, show normal output |
| `cmd \| tee log` | Watch output live and log it |
| `cmd \| sort \| uniq -c \| sort -rn` | Count and rank occurrences |

---

### Level 3: Advanced Commands

**File Descriptors**

| Command | Action |
|---------|--------|
| `exec 3> file` | Open FD 3 for writing to file |
| `exec 3< file` | Open FD 3 for reading from file |
| `echo text >&3` | Write to FD 3 |
| `exec 3>&-` | Close FD 3 |
| `>&-` | Close a file descriptor |

**Process Substitution**

| Syntax | Action |
|--------|--------|
| `diff <(cmd1) <(cmd2)` | Compare output of two commands |
| `cat <(cmd)` | Use command output as file |

**Practical Combinations**

| Pattern | Use |
|---------|-----|
| `cmd > file 2>&1` | Save all output including errors |
| `cmd > /dev/null 2>&1` | Completely silence a command |

---

## 🚀 What's Coming in Part 6

**Part 6: Shell Scripting — Automate Everything**

You will learn:
- Variables, conditionals, and loops in bash
- Exit codes and error handling
- Functions — reusable code blocks
- Reading command-line arguments
- Automating repetitive sysadmin tasks
- Writing safe, professional scripts
- 15 hands-on practices

---

## 📝 Self-Test — Can You Answer These?

1. What are the three standard streams and their file descriptor numbers?
2. What is the difference between `>` and `>>`?
3. How do you redirect stderr to a file while letting stdout go to the screen?
4. How do you redirect both stdout and stderr to the same file? (give two methods)
5. What does `2>&1` mean and why does the order matter?
6. What does the pipe operator `|` do?
7. What is the difference between `cmd > file 2>&1` and `cmd 2>&1 > file`?
8. How is a named pipe different from an unnamed pipe?
9. What does the `tee` command do? When would you use it?
10. How do you create a multi-line input using heredoc?
11. What is the difference between `<< EOF` and `<< 'EOF'`?
12. What does `wc -w <<< "hello world"` output?
13. How do you create a named pipe?
14. What does `/dev/null` do?
15. Build a single pipeline that: lists all files in `/etc`, filters for `.conf` files, sorts them alphabetically, and counts them.

**Score:** 12/15 correct = ready for Part 6.

---

*Linux SysAdmin Course | Part 5 of ∞ | Reverse Engineering Approach*
*Previous → Part 4: Text Editors — Vim, Nano, and Why They Matter*
*Next → Part 6: Shell Scripting — Automate Everything*

[← Previous](part4.md) | [Next →](part6.md)
