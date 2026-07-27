# 🐧 Linux System Administrator — Complete Course
## Part 2 of 50+: Mastering the Terminal — Navigation, Files & Directories

---

> **Reverse Engineering Approach:** We start from what you already know — folders on a computer — and reverse engineer how Linux actually stores, names, and manages every single file on the system. By the end, you won't just use commands, you'll *understand* why they work the way they do.

---

## 🎯 What You Will Achieve in Part 2

| Level | Focus | What You'll Learn |
|-------|-------|------------------|
| **⭐ Level 1: Basic** | Navigation & File Operations | Absolute/relative paths, ls, mkdir, touch, cp, mv, rm, reading files |
| **⭐ Level 2: Intermediary** | Advanced File Operations | Wildcards, find command, symbolic & hard links |
| **⭐ Level 3: Advanced** | Storage Internals | Inodes, link counts, how Linux stores files on disk |

---

## ⭐ Level 1: Basic — Navigation & File Operations

![GNU/Linux directory tree showing the hierarchical filesystem structure](https://upload.wikimedia.org/wikipedia/commons/e/ef/GNU-Linux_directory_tree.png)
*GNU/Linux directory tree by And1mu. Wikimedia Commons, CC BY-SA.*

> **Level 1 Goal:** Navigate confidently using absolute and relative paths, create/copy/move/delete files and directories, read file contents, and understand hidden files.

---



## 🔍 Section 1: Reverse Engineering the File System — It's Just a Tree

In Part 1, you saw the Linux file system starts from `/`. Let's reverse-engineer why.

### Why does Linux use a single tree?

On Windows, you have `C:\`, `D:\`, `E:\` — every drive is separate.

On Linux, everything is merged into **one tree**:

```
/
├── home/
├── etc/
├── var/
└── mnt/
    └── usb/          ← Your USB drive appears HERE inside the tree
```

When you plug in a USB drive, Linux **mounts** it into the tree at a location like `/mnt/usb` or `/media/username/USB`. The tree grows — you don't get a new `D:\`.

> 💡 **Reverse Engineering Insight:** This design means you can move an entire folder to a different physical disk by just remounting it somewhere else in the tree — without changing any paths your programs use. This is how Linux servers separate `/home`, `/var`, `/tmp` onto different disks for performance and safety.

---

## 🔍 Section 2: Paths — The Address of Every File

Every file and folder in Linux has an **address** called a **path**.

There are two types:

### Absolute Path

Starts with `/`. Always points to the **same location** no matter where you are.

```
/home/john/documents/report.txt
```

Read this as:
- Start at root `/`
- Go into `home`
- Go into `john`
- Go into `documents`
- The file is `report.txt`

### Relative Path

Does **NOT** start with `/`. It is **relative to where you currently are**.

If you are currently in `/home/john`:
```
documents/report.txt
```
This means: "starting from where I am now, go into documents, find report.txt"

### Special Relative Shortcuts

| Symbol | Meaning | Example |
|--------|---------|---------|
| `.` | Current directory | `./script.sh` = run script in current folder |
| `..` | Parent directory (one level up) | `cd ..` = go up one level |
| `~` | Your home directory | `cd ~` = go to your home |
| `-` | Previous directory | `cd -` = go back to where you just were |

### Visual Example

```
/
└── home/
    └── john/           ← You are HERE (current directory)
        ├── documents/
        │   └── report.txt
        └── pictures/
            └── photo.jpg
```

| Goal | Absolute Path | Relative Path |
|------|--------------|---------------|
| Go to documents | `cd /home/john/documents` | `cd documents` |
| Go to pictures | `cd /home/john/pictures` | `cd pictures` |
| Go up to /home | `cd /home` | `cd ..` |
| Go to /etc | `cd /etc` | `cd ../../etc` |

---

## 🔍 Section 3: The `ls` Command — Far More Than "List Files"

Most beginners use `ls` and think they know it. Let's go deeper.

### Basic Usage

```bash
ls              # List current directory
ls /etc         # List a specific directory
ls -l           # Long format (details)
ls -a           # Show ALL files including hidden
ls -la          # Long format + hidden files (most useful combination)
ls -lh          # Long format with human-readable file sizes
ls -lt          # Sort by modification time (newest first)
ls -ltr         # Sort by time, reversed (oldest first — useful for logs)
ls -R           # Recursive — show all subdirectories too
ls -ld /etc     # Show info about the DIRECTORY itself, not its contents
```

### Understanding `ls -l` Output

```bash
ls -l /etc/hosts
```

Output:
```
-rw-r--r-- 1 root root 221 Jan 15 10:30 /etc/hosts
```

Breaking this down piece by piece:

```
-rw-r--r--   1     root   root   221    Jan 15 10:30   /etc/hosts
│            │     │      │      │      │              │
│            │     │      │      │      │              └─ File name
│            │     │      │      │      └─ Last modified date/time
│            │     │      │      └─ File size in bytes
│            │     │      └─ Group owner
│            │     └─ User owner
│            └─ Number of hard links
└─ Permissions (we cover this deeply in Part 3)
```

The first character tells you the **type**:

| Character | Type |
|-----------|------|
| `-` | Regular file |
| `d` | Directory |
| `l` | Symbolic link (shortcut) |
| `c` | Character device (keyboard, terminal) |
| `b` | Block device (hard drive, USB) |
| `p` | Named pipe |
| `s` | Socket |

---

## 🔍 Section 4: Hidden Files — Linux's Secret System

In Linux, any file or folder whose name starts with a **dot (.)** is hidden.

```bash
ls ~            # Shows only visible files
ls -a ~         # Shows ALL files including hidden
```

Example output of `ls -a ~`:
```
.  ..  .bash_history  .bash_logout  .bashrc  .profile  Documents  Downloads
```

### Why Do Hidden Files Exist?

Hidden files store **configuration** for programs. Each program you install puts its settings in your home directory as a hidden file or folder.

```
~/.bashrc           ← Bash shell configuration
~/.bash_history     ← Every command you've ever typed
~/.ssh/             ← SSH keys and config (VERY important for sysadmins)
~/.profile          ← Login settings
~/.config/          ← Modern apps store config here
~/.vimrc            ← Vim editor settings (Part 4)
```

> 🔍 **Reverse Engineering Insight:** When something behaves unexpectedly, a sysadmin's first instinct is to check these hidden config files. If `bash` is acting strange, check `~/.bashrc`. If SSH won't connect, check `~/.ssh/config`.

---

## 🔍 Section 5: Creating Directories and Files

### `mkdir` — Make Directory

```bash
mkdir projects                    # Create one directory
mkdir -p projects/web/css         # Create nested directories in one command
mkdir -p projects/{web,api,docs}  # Create multiple directories at once
```

The `-p` flag means "make parent directories too, and don't error if they exist."

Without `-p`:
```bash
mkdir projects/web/css
# ERROR: projects/web doesn't exist yet!
```

With `-p`:
```bash
mkdir -p projects/web/css
# Creates: projects/ then projects/web/ then projects/web/css/
# All in one command. No errors.
```

### `touch` — Create Empty Files (and Update Timestamps)

```bash
touch file.txt                    # Create empty file
touch file1.txt file2.txt         # Create multiple files at once
touch -m file.txt                 # Update only modification time
touch -t 202401151030 file.txt    # Set a specific timestamp
```

> 🔍 **What `touch` really does:** Originally designed to "touch" a file's timestamp (update when it was last modified). Creating an empty file is a side effect — if the file doesn't exist, `touch` creates it. Sysadmins use this to create flag files that scripts check for.

### `echo` and Redirection — Create Files With Content

```bash
# Write text into a file (overwrites if exists)
echo "Hello, Linux" > myfile.txt

# APPEND text to a file (adds to the end, doesn't overwrite)
echo "Second line" >> myfile.txt

# Create a multi-line file using heredoc
cat > config.txt << EOF
server=localhost
port=8080
debug=true
EOF
```

> ⚠️ **Critical difference:**
> - `>` = **overwrite** (destroys existing content)
> - `>>` = **append** (adds to existing content)
>
> Many beginners accidentally destroy files by using `>` when they meant `>>`.

---

## 🔍 Section 6: Reading File Contents

### `cat` — Print Entire File

```bash
cat file.txt              # Print file contents
cat -n file.txt           # Print with line numbers
cat file1.txt file2.txt   # Print multiple files in sequence
```

**When NOT to use `cat`:** Never `cat` a large file (log files can be gigabytes). Use `less` instead.

### `less` — Read Large Files Safely

```bash
less /var/log/syslog
```

Navigation inside `less`:

| Key | Action |
|-----|--------|
| `Space` or `f` | Next page |
| `b` | Previous page |
| `g` | Go to beginning |
| `G` | Go to end |
| `/searchterm` | Search forward |
| `?searchterm` | Search backward |
| `n` | Next search result |
| `q` | Quit |

### `head` and `tail` — Read Parts of a File

```bash
head file.txt           # First 10 lines (default)
head -n 25 file.txt     # First 25 lines
head -n 1 file.txt      # Just the first line (great for CSV headers)

tail file.txt           # Last 10 lines
tail -n 50 file.txt     # Last 50 lines
tail -f /var/log/syslog # Follow the file live (new lines appear as written)
```

> 💡 `tail -f` is one of the most used sysadmin commands. When something breaks, you run `tail -f /var/log/syslog` and watch the log update in real time as you try to reproduce the problem.

### `wc` — Count Lines, Words, Characters

```bash
wc file.txt             # Lines, words, characters
wc -l file.txt          # Count lines only
wc -w file.txt          # Count words only
wc -c file.txt          # Count bytes/characters only

# Real use: How many users are on this system?
wc -l /etc/passwd
```

---

## 🔍 Section 7: Copying, Moving, and Renaming

### `cp` — Copy Files and Directories

```bash
cp file.txt backup.txt              # Copy file to new name (same directory)
cp file.txt /tmp/file.txt           # Copy file to different directory
cp file.txt /tmp/                   # Same — directory destination keeps original name
cp -r projects/ backup_projects/    # Copy a directory and ALL its contents
cp -p file.txt backup.txt           # Preserve permissions and timestamps
cp -i file.txt dest.txt             # Ask before overwriting (interactive)
cp -u file.txt dest.txt             # Only copy if source is newer
cp *.txt /backup/                   # Copy all .txt files to /backup/
```

> ⚠️ Without `-r`, you cannot copy a directory. You will get an error:
> ```
> cp: -r not specified; omitting directory 'projects/'
> ```

### `mv` — Move AND Rename (Same Command!)

```bash
mv old.txt new.txt                  # Rename a file
mv file.txt /tmp/                   # Move file to /tmp/
mv file.txt /tmp/newname.txt        # Move AND rename at once
mv projects/ /var/www/              # Move entire directory
mv *.log /var/log/archive/          # Move all .log files
```

> 🔍 **Reverse Engineering Insight:** There is no separate "rename" command in Linux. `mv` handles both moving and renaming because they are the same operation at the file system level — you're just changing the path where the file is recorded.

### `rm` — Delete Files and Directories

```bash
rm file.txt                         # Delete a file
rm file1.txt file2.txt              # Delete multiple files
rm -i file.txt                      # Ask before deleting (safe mode)
rm -r projects/                     # Delete directory and everything inside
rm -rf projects/                    # Force delete — NO prompts, NO mercy
rm *.tmp                            # Delete all .tmp files
```

> 🚨 **CRITICAL WARNING:** `rm -rf` is the most dangerous command in Linux.
>
> - There is **no Recycle Bin**
> - There is **no undo**
> - `rm -rf /` would delete your entire operating system (modern Linux blocks this, but variants can still destroy your system)
>
> **Professional habit:** Always double-check your path before running `rm -r`. Many sysadmins have accidentally deleted the wrong directory. Some companies have lost production databases this way.
>
> Safe practice: Run `ls` on the path first, THEN `rm -r`.
> ```bash
> ls /tmp/old_project/    # Verify it's what you think
> rm -r /tmp/old_project/ # Now delete it
> ```

---

## ⭐ Level 2: Intermediary — Advanced File Operations

![File hierarchy diagram illustrating directory structure](https://upload.wikimedia.org/wikipedia/commons/2/2c/File_Hierarchy.png)
*Example of a partial directory structure in a hierarchical file system by Peter Flass. Wikimedia Commons, CC BY-SA.*

> **Level 2 Goal:** Use wildcards to batch-operate on files, master the `find` command for powerful searches, and understand symbolic and hard links.

---

## 🔍 Section 8: Wildcards — Work on Many Files at Once

Wildcards let you match multiple files with a pattern. The **shell expands** wildcards before the command runs.

| Wildcard | Meaning | Example |
|----------|---------|---------|
| `*` | Match anything (zero or more characters) | `*.txt` = all .txt files |
| `?` | Match exactly one character | `file?.txt` = file1.txt, fileA.txt |
| `[abc]` | Match one character from the set | `file[123].txt` = file1.txt, file2.txt, file3.txt |
| `[a-z]` | Match one character in range | `file[a-z].txt` = filea.txt, fileb.txt |
| `[!abc]` | Match any character NOT in set | `file[!0-9].txt` = files not ending in numbers |
| `{a,b,c}` | Match any of these exact strings | `{*.txt,*.log}` = all txt and log files |

### Wildcard Examples

```bash
ls *.txt                    # All files ending in .txt
ls file*                    # All files starting with "file"
ls file?.txt                # file1.txt, fileA.txt, but NOT file10.txt
ls /var/log/*.log           # All log files in /var/log
cp *.conf /backup/          # Copy all config files to backup
rm temp_*                   # Delete all files starting with temp_
ls [Ff]ile.txt              # Match File.txt or file.txt
ls /dev/sd[a-z]             # Match sda, sdb, sdc... (all physical disks)
```

> 🔍 **How wildcards work — the shell expands them FIRST:**
> When you type `ls *.txt`, bash doesn't pass `*.txt` to `ls`. It first expands `*.txt` into the actual list of matching files, THEN runs `ls file1.txt file2.txt file3.txt`.
> This is why wildcards work with ANY command.

---

## 🔍 Section 9: Finding Files — `find` Command

The `find` command searches for files. It is extremely powerful.

### Basic Syntax

```bash
find [where to search] [what to look for] [what to do with results]
```

### Find by Name

```bash
find /etc -name "hosts"              # Find file named "hosts" in /etc
find /home -name "*.txt"            # Find all .txt files in /home
find / -name "passwd"               # Find "passwd" anywhere on system
find . -name "config*"              # Find files starting with "config" here
find /etc -iname "*.conf"           # Case-insensitive search
```

### Find by Type

```bash
find /etc -type f                    # Only files (not directories)
find /etc -type d                    # Only directories
find /dev -type b                    # Block devices (hard drives)
find /dev -type c                    # Character devices (terminals)
find /tmp -type l                    # Symbolic links only
```

### Find by Size

```bash
find / -size +100M                   # Files larger than 100 megabytes
find / -size +1G                     # Files larger than 1 gigabyte
find /var/log -size +50M             # Large log files
find /tmp -size -1k                  # Files smaller than 1 kilobyte
```

### Find by Time

```bash
find /etc -mtime -7                  # Modified within last 7 days
find /tmp -mtime +30                 # Modified more than 30 days ago
find /home -atime -1                 # Accessed within last 24 hours
find / -newer /etc/passwd            # Files newer than /etc/passwd
```

### Find and Do Something (Very Powerful)

```bash
# Find and delete all .tmp files
find /tmp -name "*.tmp" -delete

# Find and delete files older than 30 days
find /tmp -mtime +30 -type f -delete

# Find and print details (like ls -l for each result)
find /etc -name "*.conf" -ls

# Find and run a command on each result
find /var/log -name "*.log" -exec wc -l {} \;
# {} = the found file, \; = end of command
```

> 💡 **`find -exec` explained:** The `{}` is a placeholder for each file found. The `\;` ends the exec command. So `find /etc -name "*.conf" -exec cat {} \;` would print every config file.

---

## 🔍 Section 10: Links — Hard Links and Symbolic Links

Linux has two types of "shortcuts" to files.

### Symbolic Link (Symlink) — Like a Windows Shortcut

```bash
ln -s /path/to/original /path/to/link
```

```bash
# Create a symlink
ln -s /var/www/html /home/john/website

# Now /home/john/website points to /var/www/html
ls -la /home/john/website      # Shows: website -> /var/www/html
```

Symlinks show with `l` type and `->` in `ls -la`:
```
lrwxrwxrwx 1 john john 13 Jan 15 10:30 website -> /var/www/html
```

If the original is deleted, the symlink **breaks** (it becomes a "dangling link").

### Hard Link — Two Names for the Same Data

```bash
ln /path/to/original /path/to/hardlink
```

```bash
ln /etc/hosts /tmp/hosts_backup
```

Hard links:
- Both names point to the **exact same data on disk**
- If you delete one, the other still works perfectly
- Both files stay in sync — editing one edits both
- Cannot cross filesystem boundaries
- Cannot link directories

> 🔍 **Reverse Engineering Insight:** When you "delete" a file with `rm`, Linux doesn't actually erase the data. It removes the **name** (the link). The data is only truly deleted when there are zero names pointing to it. This is why the link count in `ls -l` matters — it shows how many names point to this data.

---

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

## ⭐ Level 3: Advanced — Storage Internals

![File table and inode table diagram showing the relationship between file descriptors, file table entries, and inodes](https://upload.wikimedia.org/wikipedia/commons/f/f8/File_table_and_inode_table.svg)
*File descriptors, file table and inode table in Unix by Qwertyus. Wikimedia Commons, CC BY-SA.*

> **Level 3 Goal:** Understand inodes, how the filesystem stores metadata separately from filenames, and what really happens when you "delete" a file.

---

## 🧠 Section 11: Deep Understanding — How Linux Stores Files

### The Inode — What a File Really Is

When you create a file, Linux creates two things:

1. **The inode** — stores all metadata: permissions, owner, size, timestamps, location on disk
2. **The directory entry** — maps the filename to the inode number

This is why you can have two names (hard links) for one file — two directory entries pointing to the same inode.

```bash
# See inode numbers
ls -i ~/practice/project1/docs/README.md

# See inode usage on your filesystem
df -i
```

### The Real Meaning of "Delete"

When you `rm file.txt`:
1. Linux removes the **directory entry** (the name)
2. The inode's **link count** drops by 1
3. If link count reaches **0**, the disk space is marked as free
4. The data isn't actually erased — it just becomes "available to overwrite"

This is why:
- Hard links protect data (link count > 1 even after one name is removed)
- Forensic tools can sometimes recover deleted files (data not overwritten yet)
- SSD "secure erase" is a different, explicit process

---

## 📋 Summary — Complete Command Reference for Part 2

### Level 1: Basic — Navigation & File Operations

**Navigation**
| Command | What It Does |
|---------|-------------|
| `pwd` | Show current directory |
| `cd /path` | Go to absolute path |
| `cd subdir` | Go to relative path |
| `cd ..` | Go up one level |
| `cd ~` | Go to home directory |
| `cd -` | Go to previous directory |

**Listing**
| Command | What It Does |
|---------|-------------|
| `ls` | List files |
| `ls -la` | List all files with full details |
| `ls -lh` | Human-readable sizes |
| `ls -lt` | Sort by time, newest first |
| `ls -ltr` | Sort by time, oldest first |
| `ls -ld /dir` | Show directory itself, not contents |

**Creating**
| Command | What It Does |
|---------|-------------|
| `mkdir dir` | Create directory |
| `mkdir -p a/b/c` | Create nested directories |
| `touch file` | Create empty file |
| `echo "text" > file` | Create file with content |
| `echo "text" >> file` | Append to file |

**Reading**
| Command | What It Does |
|---------|-------------|
| `cat file` | Print entire file |
| `cat -n file` | Print with line numbers |
| `less file` | Page through file |
| `head -n 20 file` | First 20 lines |
| `tail -n 20 file` | Last 20 lines |
| `tail -f file` | Follow file live |
| `wc -l file` | Count lines |

**Copying and Moving**
| Command | What It Does |
|---------|-------------|
| `cp file dest` | Copy file |
| `cp -r dir dest` | Copy directory |
| `cp -i file dest` | Ask before overwrite |
| `mv old new` | Move or rename |

**Deleting**
| Command | What It Does |
|---------|-------------|
| `rm file` | Delete file |
| `rm -i file` | Ask before deleting |
| `rm -r dir` | Delete directory and contents |

### Level 2: Intermediary — Finding & Links

**Finding**
| Command | What It Does |
|---------|-------------|
| `find . -name "*.txt"` | Find by name |
| `find . -type d` | Find only directories |
| `find . -size +1M` | Find large files |
| `find . -mtime -7` | Modified in last 7 days |

**Links**
| Command | What It Does |
|---------|-------------|
| `ln -s src dest` | Create symbolic link |
| `ln src dest` | Create hard link |

---

## 🚀 What's Coming in Part 3

**Part 3: Users, Groups, and Permissions — Who Can Do What**

You will learn:
- The permission system in deep detail (read/write/execute for user/group/other)
- How to read permission strings like `-rwxr-xr--`
- `chmod` — change who can access a file
- `chown` — change who owns a file
- `sudo` — temporarily become root safely
- The `/etc/passwd` and `/etc/shadow` files in detail
- `useradd`, `usermod`, `userdel` — managing users
- Real scenarios: setting up a shared server directory
- 15 hands-on practices

---

## 📝 Self-Test — Can You Answer These?

Before moving to Part 3, answer without looking:

1. What is the difference between `/home/john/file.txt` and `./file.txt`?
2. What does `cd -` do?
3. How do you create the directory structure `a/b/c/d` in one command?
4. What is the difference between `>` and `>>` when redirecting?
5. Why should you NEVER use `rm -rf` carelessly?
6. What does `tail -f` do and when would a sysadmin use it?
7. What does a file starting with `.` mean in Linux?
8. What is the difference between a symlink and a hard link?
9. How do you find all files larger than 100MB on the system?
10. What does `ls -ltr` show and why is it useful for sysadmins?

**Score:** 8/10 correct = ready for Part 3.

---

*Linux SysAdmin Course | Part 2 of 50+ | Reverse Engineering Approach*
*Previous → Part 1: What Is Linux & How It Really Works*
*Next → Part 3: Users, Groups, and Permissions — Who Can Do What*
[← Previous](part1.md) | [Next →](part3.md)
