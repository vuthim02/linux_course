## 💻 PRACTICE SECTION — 15 Hands-On Exercises

> Type every command yourself. Do not copy-paste. Muscle memory matters.

### Level 1 Practices — Basic Navigation & File Operations

---

### ✅ Practice 1: Path Exploration

```bash
# Check where you are
pwd

# Go to root and explore
cd /
ls -la

# Note the difference between / and ~
echo "Root is: /"
echo "Home is: $HOME"
cd ~
pwd
```

**Task:** Write down the absolute path of your home directory.

---

### ✅ Practice 2: Relative Path Navigation

```bash
# Go to /var/log
cd /var/log

# Now go to /var (parent) using relative path
cd ..
pwd    # Should show /var

# Go to /etc using relative path from /var
cd ../etc
pwd    # Should show /etc

# Go back to where you were last
cd -
pwd    # Should show /var/log
```

---

### ✅ Practice 3: Master `ls` Options

```bash
cd /etc

# Basic list
ls

# With hidden files
ls -a

# Long format
ls -l

# Long format, human readable sizes, sorted by time
ls -lht

# Long format, sorted oldest first
ls -ltr

# Show only directories
ls -ld */

# Show just the directory info (not contents)
ls -ld /etc
```

**Task:** Find the 3 most recently modified files in `/etc` using `ls`.

---

### ✅ Practice 4: Build a Practice Directory Tree

```bash
# Go to your home directory
cd ~

# Create a complete project structure in one command
mkdir -p practice/project1/{src,tests,docs,logs}
mkdir -p practice/project2/{src,tests,docs,logs}
mkdir -p practice/shared/configs

# Verify the structure
ls -R practice/
```

Expected output:
```
practice/:
project1  project2  shared

practice/project1:
docs  logs  src  tests

practice/project1/docs:
...
```

---

### ✅ Practice 5: Create Files Multiple Ways

```bash
cd ~/practice/project1

# Method 1: touch (empty file)
touch src/main.py
touch src/helper.py
touch tests/test_main.py

# Method 2: echo with redirect
echo "# Project Documentation" > docs/README.md
echo "Version: 1.0" >> docs/README.md
echo "Author: $(whoami)" >> docs/README.md

# Method 3: heredoc (multi-line)
cat > logs/app.log << EOF
2024-01-15 10:00:01 INFO Application started
2024-01-15 10:01:05 INFO Connected to database
2024-01-15 10:02:33 WARNING High memory usage detected
2024-01-15 10:03:00 ERROR Failed to write to disk
EOF

# Verify all files
ls -la src/ tests/ docs/ logs/
```

---

### ✅ Practice 6: Read Files Different Ways

```bash
cd ~/practice/project1

# Read entire file
cat docs/README.md

# Read with line numbers
cat -n logs/app.log

# Read just first 2 lines
head -n 2 logs/app.log

# Read just last 2 lines
tail -n 2 logs/app.log

# Count lines
wc -l logs/app.log

# Watch for new lines (open new terminal, add a line)
tail -f logs/app.log
# (Press Ctrl+C to stop)
```

---

### Level 2 Practices — Wildcards, Finding Files & Links

---

### ✅ Practice 7: Wildcards in Action

```bash
cd ~/practice/project1/src

# Create test files
touch app.py utils.py config.py backup.py old_app.py

cd ~/practice/project1

# List all Python files
ls src/*.py

# List files starting with "a"
ls src/a*

# List files with exactly 6 characters before .py
ls src/???.py

# Copy all .py files to docs
cp src/*.py docs/

# List what's in docs now
ls docs/

# Remove the copies (be specific!)
rm docs/*.py

# Verify they're gone
ls docs/
```

---

### ✅ Practice 8: Copy Files and Directories

```bash
cd ~/practice

# Copy a single file
cp project1/docs/README.md project2/docs/README.md

# Copy multiple files
cp project1/src/*.py shared/

# Copy a whole directory
cp -r project1/ project1_backup/

# Verify
ls -la project1_backup/
diff project1/docs/README.md project2/docs/README.md
# No output = files are identical
```

---

### ✅ Practice 9: Move and Rename

```bash
cd ~/practice/project1

# Rename a file
mv src/old_app.py src/legacy.py
ls src/

# Move file to different directory
mv src/backup.py logs/

# Move and rename at the same time
mv logs/backup.py logs/backup_2024.py
ls logs/

# Move entire directory
mv project1_backup/ /tmp/
ls ~/practice/
ls /tmp/project1_backup/
```

---

### ✅ Practice 10: Safe File Deletion Practice

```bash
cd /tmp/project1_backup

# ALWAYS list before deleting
ls logs/

# Delete one file safely
rm -i logs/app.log
# It asks: "remove 'logs/app.log'?" — type y and Enter

# Delete multiple files with confirmation
rm -i src/*.py

# Delete a directory tree
ls -la    # Check what's here first
cd /tmp   # Move OUT of the directory first (never delete a dir you're inside)
rm -r project1_backup/

# Confirm it's gone
ls /tmp/ | grep project1
```

---

### ✅ Practice 11: Hidden Files Exploration

```bash
# List all hidden files in your home directory
ls -la ~

# See your bash configuration
cat ~/.bashrc

# See your command history (last 20 commands)
tail -n 20 ~/.bash_history

# See what history is stored
wc -l ~/.bash_history

# See your profile settings
cat ~/.profile

# Check if .ssh exists (where your SSH keys will live)
ls -la ~/.ssh 2>/dev/null || echo "No .ssh directory yet"
```

---

### ✅ Practice 12: Create Symlinks

```bash
cd ~/practice

# Create a symlink to project1's logs from the shared folder
ln -s ~/practice/project1/logs ~/practice/shared/project1_logs

# List it
ls -la ~/practice/shared/

# The -> shows it's a symlink
# Access the logs through the symlink
ls ~/practice/shared/project1_logs/

# This is the same as
ls ~/practice/project1/logs/

# Create a symlink to a file
ln -s ~/practice/project1/docs/README.md ~/practice/shared/main_readme.md
cat ~/practice/shared/main_readme.md
```

---

### ✅ Practice 13: Advanced `find` Practice

```bash
# Find all Python files in your practice directory
find ~/practice -name "*.py"

# Find all directories
find ~/practice -type d

# Find all files modified in the last hour
find ~/practice -mmin -60 -type f

# Find all empty files
find ~/practice -empty -type f

# Find and count all files
find ~/practice -type f | wc -l

# Find large files in /var/log
find /var/log -size +1M -type f 2>/dev/null

# Find files owned by you
find ~/practice -user $(whoami) -type f
```

---

### ✅ Practice 14: Real Sysadmin Scenario — Disk Investigation

```bash
# Find the largest files on the system (run as regular user)
find /var -size +10M -type f 2>/dev/null | head -10

# Find files in /tmp older than 7 days
find /tmp -mtime +7 -type f 2>/dev/null

# Find all .log files and show their sizes
find /var/log -name "*.log" -type f -ls 2>/dev/null

# Count how many config files are in /etc
find /etc -name "*.conf" -type f | wc -l

# Find recently changed system files
find /etc -mtime -1 -type f 2>/dev/null
```

> 💡 `2>/dev/null` sends error messages (stderr) to the void — suppresses "Permission denied" errors when searching directories you can't read. You'll learn this properly in Part 6 (Redirection).

---

### Level 3 Practices — Real SysAdmin Builds

---

### ✅ Practice 15: Build and Verify a Full Structure

```bash
# Build this exact structure from scratch:
#
# ~/server_setup/
# ├── web/
# │   ├── html/index.html
# │   ├── css/style.css
# │   └── logs/access.log
# ├── database/
# │   ├── backups/
# │   └── configs/db.conf
# └── scripts/
#     └── deploy.sh

mkdir -p ~/server_setup/{web/{html,css,logs},database/{backups,configs},scripts}

echo "<html><body>Hello Server</body></html>" > ~/server_setup/web/html/index.html
echo "body { font-family: Arial; }" > ~/server_setup/web/css/style.css
echo "2024-01-15 10:00 GET / 200" > ~/server_setup/web/logs/access.log
echo "host=localhost\nport=5432\nname=mydb" > ~/server_setup/database/configs/db.conf
echo "#!/bin/bash\necho 'Deploying...'" > ~/server_setup/scripts/deploy.sh

# Verify the entire structure
find ~/server_setup -type f -ls

# Count total files created
find ~/server_setup -type f | wc -l
# Should be 5 files
```

---



---

[← Previous](13-section-10-links-hard-links.md) | [↑ Index](index.md) | [Next →](15-level-3-advanced-storage-internals.md)
