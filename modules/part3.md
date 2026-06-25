# 🐧 Linux System Administrator — Complete Course
## Part 3 of ∞: Users, Groups, and Permissions — Who Can Do What

---

> **Reverse Engineering Approach:** Instead of memorizing chmod numbers, we will start with a simple question — *why does Linux have permissions at all?* Then we will break open every file, every user database, and every access control mechanism until you understand them from the inside out.

---

## 🎯 What You Will Achieve in Part 3

| Level | Focus | What You'll Learn |
|-------|-------|------------------|
| **⭐ Level 1: Basic** | Permission Fundamentals | Reading permission strings, chmod (symbolic & numeric), chown, chgrp |
| **⭐ Level 2: Intermediary** | User & Group Administration | /etc/passwd, /etc/shadow, /etc/group, useradd/usermod/userdel, group management, sudo, umask |
| **⭐ Level 3: Advanced** | Advanced Access Control | SUID/SGID/Sticky Bit, ACLs, troubleshooting checklist, deep internals |

---

## ⭐ Level 1: Basic — Permission Fundamentals

![Unix permissions diagram showing read, write, and execute bits for owner, group, and others](https://drawings.jvns.ca/drawings/unixpermissions.png)
*Unix permissions diagram by Julia Evans (jvns.ca). CC BY.*

> **Level 1 Goal:** Read any permission string fluently, change permissions with chmod (both symbolic and numeric), and change file ownership with chown and chgrp.

---



## 🔍 Section 1: Why Permissions Exist — The Core Problem

Linux was designed from day one as a **multi-user system**. This means many people use the same machine at the same time.

Ask yourself: what stops one user from deleting another user's files? What stops a student from reading the exam answers stored in the professor's folder? What stops a hacked web server from wiping your entire system?

**The answer: permissions.**

Linux has three layers of access control:

```
Layer 1: Standard Permissions (rwx)
  └─ Every file has an owner, group, and "others" permission
  └─ Controls read, write, execute

Layer 2: Special Permissions (SUID, SGID, Sticky Bit)
  └─ Extended controls for special cases
  └─ "Run this file as its owner, not as me"

Layer 3: Access Control Lists (ACLs)
  └─ Fine-grained: "User A can read, User B can write"
  └─ Everyone else gets nothing
```

Most courses stop at Layer 1. A real sysadmin needs all three.

---

## 🔍 Section 2: Reading Permission Strings — The Secret Language

Every file and directory in Linux has a permission string. Run this right now:

```bash
ls -l /etc/hosts
```

You will see something like:

```
-rw-r--r-- 1 root root 221 Jan 15 10:30 /etc/hosts
```

The first 10 characters are the **permission string**. Learn this.

### Breaking Down the 10 Characters

```
Position:  1  2 3 4  5 6 7  8 9 10
          ┌─┐└─┬─┘ └─┬─┘ └─┬─┘
          │   │      │     └── Others (everyone else)
          │   │      └──────── Group owner's permissions
          │   └─────────────── User owner's permissions
          └─────────────────── File type
```

### Position 1: File Type

| Character | Meaning |
|-----------|---------|
| `-` | Regular file |
| `d` | Directory |
| `l` | Symbolic link |
| `c` | Character device (keyboard, terminal) |
| `b` | Block device (disk, USB) |
| `p` | Named pipe (FIFO) |
| `s` | Socket |

### Positions 2-4: User (Owner) Permissions

| Character | Meaning |
|-----------|---------|
| `r` | Read — can view file contents |
| `w` | Write — can modify or delete file |
| `x` | Execute — can run as a program |
| `-` | That permission is NOT granted |

### Positions 5-7: Group Permissions

Same `r`, `w`, `x` but for any user in the file's group.

### Positions 8-10: Others Permissions

Same `r`, `w`, `x` but for every other user on the system.

### Real Examples

```bash
-rw-------  1 alice  alice   1024 Jan 15 10:30 private.txt
```
Owner can read and write. No one else can do anything.

```bash
-rwxr-xr-x  1 root   root   35000 Jan 15 10:30 /usr/bin/ls
```
Owner can read, write, execute. Group and others can read and execute (but not modify).

```bash
drwxr-xr-x  2 alice  alice   4096 Jan 15 10:30 Documents/
```
Directory. Owner can read, write, enter. Others can read and enter but not create or delete files.

### What rwx Means for DIRECTORIES (Critical Difference)

For directories, rwx means something **completely different** than for files:

| Permission | On a FILE | On a DIRECTORY |
|-----------|-----------|----------------|
| `r` (read) | View file contents | List directory contents (`ls`) |
| `w` (write) | Modify file contents | Create, rename, or delete files INSIDE the directory |
| `x` (execute) | Run as a program | Enter the directory (`cd` into it), access files inside |

> 🚨 **Critical:** You need **execute (x)** on a directory to access any files inside it, even if those files have their own permissions. `chmod -x` on a directory effectively locks everyone out of its contents.

```bash
# Example: directory with r but no x
ls -ld /tmp/test
# drw-r--r--  2 alice alice 4096 ...
ls /tmp/test     # Can LIST files
cd /tmp/test     # FAIL — no x permission
cat /tmp/test/file.txt  # FAIL — no x permission
```

---

## 🔍 Section 3: chmod — Changing Permissions

### Method 1: Symbolic Mode (Easier to Read)

```bash
chmod [who][operator][permission] file
```

| Who | Meaning |
|-----|---------|
| `u` | User (owner) |
| `g` | Group |
| `o` | Others |
| `a` | All (user + group + others) |

| Operator | Meaning |
|----------|---------|
| `+` | Add permission |
| `-` | Remove permission |
| `=` | Set exactly (overwrites) |

```bash
# Give owner execute permission
chmod u+x script.sh

# Remove write from group and others
chmod go-w file.txt

# Give group read and execute, set others to read-only
chmod g=rx,o=r file.txt

# Give everyone execute
chmod a+x script.sh

# Add multiple at once
chmod u+rwx,g+rx,o+r file.sh
```

### Method 2: Numeric (Octal) Mode (Faster, Professional)

Every permission has a number:

```
r = 4
w = 2
x = 1
- = 0
```

Add the numbers together for each group:

```bash
# rwx = 4+2+1 = 7  (full access)
# r-x = 4+0+1 = 5  (read + execute)
# r-- = 4+0+0 = 4  (read only)
# -wx = 0+2+1 = 3  (write + execute)
# --- = 0+0+0 = 0  (no permissions)
```

**The three digits** = owner + group + others:

```bash
chmod 755 file.sh
# 7 (rwx) for owner, 5 (r-x) for group, 5 (r-x) for others

chmod 644 file.txt
# 6 (rw-) for owner, 4 (r--) for group, 4 (r--) for others

chmod 600 private.key
# 6 (rw-) for owner, 0 (---) for group, 0 (---) for others

chmod 700 script.sh
# 7 (rwx) for owner, 0 (---) for everyone else

chmod 777 dangerous.sh
# 💀 Everyone can do EVERYTHING. Avoid this.
```

### Quick Reference — Most Common Permissions

| Number | String | Meaning | Use Case |
|--------|--------|---------|----------|
| `644` | `-rw-r--r--` | Owner read/write, everyone else read | Regular files |
| `755` | `-rwxr-xr-x` | Owner full, others read/execute | Executables, scripts |
| `700` | `-rwx------` | Only owner can do anything | Private scripts, SSH keys |
| `600` | `-rw-------` | Only owner can read/write | Private config, SSH private keys |
| `640` | `-rw-r-----` | Owner read/write, group read | Shared project files |
| `664` | `-rw-rw-r--` | Owner + group read/write | Collaborative files |
| `777` | `-rwxrwxrwx` | Everyone can do everything | AVOID |
| `000` | `----------` | No one can do anything | Lock a file |

```bash
# Practice: Convert between symbolic and numeric
# chmod u=rwx,g=rx,o=rx   =  755
# chmod u=rw,g=r,o=       =  640
# chmod u=rwx,g=,o=       =  700
# chmod u=rw,g=rw,o=r     =  664
```

---

## 🔍 Section 4: chown and chgrp — Changing Ownership

### chown — Change Owner

```bash
# Change only the user owner
sudo chown alice file.txt

# Change both user and group
sudo chown alice:developers file.txt

# Change only the group (colon without username)
sudo chown :developers file.txt

# Change recursively (entire directory tree)
sudo chown -R alice:developers /home/alice/project

# Use reference file to copy ownership
sudo chown --reference=template.txt target.txt
```

### chgrp — Change Group Only (Simpler When You Only Need Group)

```bash
sudo chgrp developers file.txt
sudo chgrp -R developers /shared/project
```

> 💡 `chown alice:group file` changes both in one command. This is the most common pattern professionals use.

### Who Can Change Ownership?

Only **root** can change the owner of a file to another user. This is a security rule: you cannot "give away" your files to avoid responsibility.

However, a user can change the **group** of their own files to any group they belong to:

```bash
# alice is in group "developers"
chgrp developers myfile.txt   # Works — alice belongs to developers
chgrp admins myfile.txt       # Fails — alice is not in admins
```

---

## ⭐ Level 2: Intermediary — User & Group Administration

![Linux file permissions illustrated — owner, group, and others access](https://assets.bytebytego.com/diagrams/0259-linux-permissions-copy.png)
*Linux file permissions illustrated. ByteByteGo.*

> **Level 2 Goal:** Master user and group management — understand the user database files, create/modify/delete users and groups, configure sudo safely, and control default permissions with umask.

---

## 🔍 Section 5: /etc/passwd — The User Database (Deep Dive)

This is the oldest user database in Unix. Every user account has one line.

```bash
cat /etc/passwd
```

Each line has 7 fields separated by colons:

```
alice:x:1001:1001:Alice Johnson:/home/alice:/bin/bash
│     │ │     │      │              │           │
│     │ │     │      │              │           └── Shell (what runs on login)
│     │ │     │      │              └────────────── Home directory
│     │ │     │      └───────────────────────────── GECOS (full name, comma-separated)
│     │ │     └──────────────────────────────────── Group ID (GID)
│     │ └────────────────────────────────────────── User ID (UID)
│     └──────────────────────────────────────────── Password placeholder (x = shadow)
└────────────────────────────────────────────────── Username
```

### Field Details

| Field | Example | Meaning |
|-------|---------|---------|
| Username | `alice` | Login name (1-32 chars, no uppercase on some systems) |
| Password | `x` | If `x`, password is in `/etc/shadow`. If `*` or `!`, account is locked |
| UID | `1001` | User ID. 0=root, 1-999=system, 1000+=regular users |
| GID | `1001` | Primary group ID (from `/etc/group`) |
| GECOS | `Alice Johnson` | Full name or description. Comma-separated fields |
| Home | `/home/alice` | User's home directory |
| Shell | `/bin/bash` | Login shell. `/sbin/nologin` or `/bin/false` disables login |

### UID Ranges — The Official Map

```bash
UID 0       → root (superuser)
UID 1-999   → System accounts (daemons, services)
               1 = bin, 2 = daemon, 8 = mail...
UID 1000+   → Regular human users
```

> 🔍 **Reverse Engineering Insight:** Your UID is your true identity. You can change your username, your home directory, your shell — but your UID stays the same. Linux identifies you by UID, not by name.

### Special Accounts You Will See

```bash
root:x:0:0:root:/root:/bin/bash       # All-powerful
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
bin:x:2:2:bin:/bin:/usr/sbin/nologin
sys:x:3:3:sys:/dev:/usr/sbin/nologin
nobody:x:65534:65534:nobody:/nonexistent:/usr/sbin/nologin   # Least-privilege account
```

> 💡 The `nobody` account is used by services that need minimal privileges. If a web server gets hacked while running as `nobody`, the attacker has almost no power.

---

## 🔍 Section 6: /etc/shadow — The Password File (Sensitive!)

```bash
sudo cat /etc/shadow
```

This file is only readable by root. Each line corresponds to `/etc/passwd`:

```
alice:$6$xyz123$abc...def:19876:0:99999:7:30::
│      │                      │     │   │   │ ││
│      │                      │     │   │   │ │└─ Unused (reserved)
│      │                      │     │   │   │ └── Account expiration days
│      │                      │     │   │   └──── Warning days before password expires
│      │                      │     │   └──────── Maximum password age (days)
│      │                      │     └──────────── Minimum password age (days)
│      │                      └────────────────── Last password change (days since epoch)
│      └───────────────────────────────────────── Hashed password
└───────────────────────────────────────────────── Username
```

### Password Hash Format

```
$type$salt$hash
$6$xyz123$abc...def
```

| Type | Hash Algorithm |
|------|---------------|
| `$1$` | MD5 (weak, avoid) |
| `$2y$` | Blowfish |
| `$5$` | SHA-256 |
| `$6$` | SHA-512 (current standard) |
| `$y$` | Yescrypt (newer, on some distros) |

### Shadow Flags

| Value | Meaning |
|-------|---------|
| `*` | Account is locked. No login possible. |
| `!` | Password is locked. May have been set then locked. |
| `!!` | No password set. User cannot log in with password. |
| Empty | No password. User cannot log in (on modern systems). |

> 💡 **Practical note:** To lock a user account: `sudo passwd -l username`. To unlock: `sudo passwd -u username`. This places `!` or removes `!` from the shadow file.

---

## 🔍 Section 7: /etc/group — Group Database

```bash
cat /etc/group
```

```
developers:x:1001:alice,bob,charlie
│          │ │    │
│          │ │    └── Supplementary members (comma-separated)
│          │ └─────── Group ID (GID)
│          └───────── Group password (x = managed by shadow)
└──────────────────── Group name
```

### The Primary vs Supplementary Groups

Every user has exactly **one primary group** (from `/etc/passwd` field 4) and can belong to **many supplementary groups** (from `/etc/group`).

```bash
# When alice creates a file, the group is her PRIMARY group:
$ touch test.txt
$ ls -l test.txt
-rw-rw-r-- 1 alice alice 0 Jan 15 10:30 test.txt
#                    └── primary group (also called "alice")
```

> 🔍 **Reverse Engineering Insight:** By default every user gets a "User Private Group" (UPG) — a group with the same name as the user. This is why `alice` owns both user and group. This prevents the need for a shared "users" group that could accidentally give access.

---

## 🔍 Section 8: User Management Commands

### useradd — Create a User

```bash
# Simplest form (uses defaults)
sudo useradd bob

# With all options specified
sudo useradd -u 1050 -g developers -G sudo,docker -c "Bob Smith" -m -s /bin/bash bob

# What each flag means:
# -u 1050        → UID 1050
# -g developers  → Primary group
# -G sudo,docker → Supplementary groups
# -c "Bob Smith" → Full name (GECOS)
# -m             → Create home directory (/home/bob)
# -s /bin/bash   → Login shell
```

### Defaults for useradd

```bash
# See all defaults the system uses
useradd -D
# Output:
# GROUP=100       ← Default group if -g not specified
# HOME=/home       ← Home directory prefix
# INACTIVE=-1      ← Password expiry disabled
# EXPIRE=          ← No account expiry
# SHELL=/bin/bash  ← Default shell
# SKEL=/etc/skel   ← Template for home directory
# CREATE_MAIL_SPOOL=yes
```

### The SKEL Directory — Every New Home Comes From Here

```bash
ls -la /etc/skel/
# .bashrc  .profile  .bash_logout  ...
```

When `useradd -m` creates a home directory, it copies everything from `/etc/skel/`. This is why every new user gets the same default configuration files.

```bash
# Add a company-wide welcome message to all NEW users
echo "echo 'Welcome to the company!'" | sudo tee -a /etc/skel/.profile
```

### usermod — Modify a User

```bash
# Change username
sudo usermod -l newname oldname
# Note: also rename the home directory manually

# Change UID
sudo usermod -u 1055 bob

# Change primary group
sudo usermod -g developers bob

# Add to supplementary groups (APPEND, don't replace)
sudo usermod -aG sudo bob
# ⚠️ Without -a, usermod -G REPLACES all groups. Always use -a with -G.

# Lock a user account
sudo usermod -L bob     # Adds ! to shadow

# Unlock
sudo usermod -U bob     # Removes ! from shadow

# Change home directory
sudo usermod -d /new/home/bob -m bob
# -m moves contents from old home to new home

# Set account expiry
sudo usermod -e 2025-12-31 bob
# After this date, account cannot be used

# Change shell (prevent login)
sudo usermod -s /sbin/nologin bob

# Change full name
sudo usermod -c "Bob Smith (Contractor)" bob
```

### userdel — Delete a User

```bash
# Remove user but leave home directory
sudo userdel bob

# Remove user AND home directory, mail spool
sudo userdel -r bob

# Force delete (even if still logged in)
sudo userdel -f bob
```

> 🚨 **Warning:** Never delete a user whose UID still owns files. The files become orphaned (shown as numeric UID in `ls -l`). Always find and reassign files first:
> ```bash
> find / -user bob -type f 2>/dev/null
> ```

### passwd — Manage Passwords

```bash
# Change your own password
passwd

# Change another user's password (root only)
sudo passwd bob

# Lock a password
sudo passwd -l bob

# Unlock
sudo passwd -u bob

# Force password change on next login
sudo passwd -e bob
# This sets the "last changed" field to 0

# Delete a password (no password login — careful!)
sudo passwd -d bob

# Check password status
sudo passwd -S bob
# bob P 2024-01-15 0 99999 7 -1
# (P=usable, L=locked, NP=no password)
```

---

## 🔍 Section 9: Group Management Commands

### groupadd — Create a Group

```bash
sudo groupadd developers
sudo groupadd -g 2000 developers     # Specific GID
sudo groupadd -r backend              # System group (GID < 1000)
```

### groupmod — Modify a Group

```bash
sudo groupmod -n newname oldname      # Rename group
sudo groupmod -g 2500 developers      # Change GID
```

### groupdel — Delete a Group

```bash
sudo groupdel oldproject
# Fails if group is a primary group for any user
```

### gpasswd — Manage Group Membership

```bash
# Add user to group
sudo gpasswd -a alice developers

# Remove user from group
sudo gpasswd -d alice developers

# Set group administrators (users who can add/remove members)
sudo gpasswd -A alice developers
```

### groups — See Group Membership

```bash
# Show your groups
groups

# Show another user's groups
groups alice

# Show all groups a user belongs to (primary + supplementary)
id alice
# uid=1001(alice) gid=1001(alice) groups=1001(alice),4(adm),27(sudo),1002(developers)
```

### The `newgrp` Command — Change Primary Group Temporarily

```bash
# If you belong to multiple groups, change your effective group
newgrp developers
# All files created now will have 'developers' as group
# Type 'exit' to go back to original group
```

---

## 🔍 Section 10: sudo — Becoming Root Safely

The `sudo` command lets authorized users run commands as root (or other users) without knowing the root password.

### How sudo Works

```bash
sudo whoami
# root

sudo -u alice whoami
# alice
```

### Viewing Your Sudo Privileges

```bash
sudo -l
# Lists all commands you are allowed to run
```

### The /etc/sudoers File

```bash
sudo visudo   # ALWAYS use visudo, never edit directly
```

`visudo` locks the file, validates syntax on save, and prevents you from locking yourself out.

### Sudoers Syntax

```
who    where=(whom)  commands
alice  ALL=(ALL)     ALL
```

| Field | Meaning |
|-------|---------|
| `who` | User or group (use `%groupname` for groups) |
| `where` | Which hosts this applies to (`ALL` = any) |
| `(whom)` | Which user they can run commands as |
| `commands` | Which commands (`ALL` = any) |

### Real Sudoers Examples

```bash
# Give alice full sudo access
alice ALL=(ALL) ALL

# Give everyone in 'sudo' group full access
%sudo ALL=(ALL) ALL

# Give bob permission to only restart the web server
bob ALL=(root) /usr/bin/systemctl restart nginx, /usr/bin/systemctl status nginx

# Give developers group permission to run package updates without password
%developers ALL=(root) NOPASSWD: /usr/bin/apt update, /usr/bin/apt upgrade

# Give alice permission to run as any user EXCEPT root
alice ALL=(ALL, !root) ALL

# Run only specific commands as specific users
bob ALL=(dbadmin) /usr/bin/psql
```

### Important sudo Options

```bash
# Run as different user
sudo -u postgres psql

# Run as root but keep current environment
sudo -E ./script.sh

# Start a shell as root
sudo -s          # Root shell with current dir and env
sudo -i          # Root shell with root's environment (login shell)

# Edit a file safely (uses your $EDITOR)
sudo -e /etc/hosts
```

> 🚨 **Security Rule:** Grant the least privilege needed. Never give `ALL=(ALL) ALL` to anyone unless absolutely necessary. Use specific commands.

---

## ⭐ Level 3: Advanced — Advanced Access Control

![Traditional Unix inode block map showing direct, single indirect, double indirect, and triple indirect pointers](https://loonytek.files.wordpress.com/2015/07/inode_blog_post1.png)
*Traditional Unix inode block map diagram. Loonytek.*

> **Level 3 Goal:** Understand and configure special permissions (SUID, SGID, Sticky Bit), control default permissions with umask, implement fine-grained access with ACLs, and systematically troubleshoot permission problems.

---

## 🔍 Section 11: Special Permissions — SUID, SGID, Sticky Bit

### SUID — Set User ID (Position 3 becomes `s`)

When a file with SUID is executed, it runs as the **file's owner**, not as the user who ran it.

```bash
ls -l /usr/bin/passwd
# -rwsr-xr-x 1 root root 59976 Jan 15 10:30 /usr/bin/passwd
#   ↑
#   s = SUID set
```

When you (a regular user) run `passwd`, it runs as **root** because the file is owned by root and has SUID. This allows it to write to `/etc/shadow` — which you normally cannot access.

```bash
# Set SUID
chmod u+s script.sh
# or
chmod 4755 script.sh    # 4 = SUID
```

```bash
# Remove SUID
chmod u-s script.sh
```

### SGID — Set Group ID (Position 6 becomes `s`)

**On files:** The file runs with the group of the file, not the user's group.

```bash
ls -l /usr/bin/wall
# -rwxr-sr-x 1 root tty 34832 Jan 15 10:30 /usr/bin/wall
#          ↑
#          s = SGID set
```

**On directories (MOST USEFUL):** Files created inside an SGID directory inherit the directory's group, not the user's primary group.

```bash
# Create a shared directory where all files stay in the 'project' group
sudo mkdir /shared/project
sudo chgrp project /shared/project
sudo chmod g+s /shared/project
# Now every file created in /shared/project gets group = 'project'
```

```bash
# Set SGID on directory
chmod g+s /shared/project
# or
chmod 2755 /shared/project   # 2 = SGID
```

### Sticky Bit (Position 9 becomes `t`)

On directories with the sticky bit, users can only delete their **own** files, even if they have write access to the directory.

```bash
ls -ld /tmp
# drwxrwxrwt 20 root root 4096 Jan 15 10:30 /tmp
#               ↑
#               t = Sticky Bit set
```

Every user can write to `/tmp`, but user Alice cannot delete Bob's files.

```bash
# Set Sticky Bit
chmod o+t /shared/directory
# or
chmod 1755 /shared/directory    # 1 = Sticky Bit
```

### Special Permissions Quick Reference

| Special Bit | Numeric | On Files | On Directories |
|-------------|---------|----------|----------------|
| SUID | 4xxx | Runs as file owner | Ignored |
| SGID | 2xxx | Runs as file group | New files inherit directory's group |
| Sticky | 1xxx | Ignored (historically: keep in memory) | Users can only delete their own files |

### Finding Special Permissions

```bash
# Find all SUID files on the system (potential security risk)
find / -perm -4000 -type f 2>/dev/null

# Find all SGID files
find / -perm -2000 -type f 2>/dev/null

# Find world-writable directories with sticky bit (should be rare)
find / -type d -perm -1000 -ls 2>/dev/null
```

> 🚨 **Security:** SUID files are a common attack vector. A misconfigured SUID binary can let an attacker escalate to root. Audit them regularly.

---

## 🔍 Section 12: umask — Default Permissions

When you create a file or directory, it gets **default permissions**. The `umask` subtracts from those defaults.

### How umask Works

```
File default:       666 (rw-rw-rw-)
Directory default:  777 (rwxrwxrwx)
Subtract umask:     --- umask value
Result:             Actual permissions
```

```bash
# Check current umask
umask
# 0022

# What this means:
# Files:   666 - 022 = 644 (rw-r--r--)
# Dirs:    777 - 022 = 755 (rwxr-xr-x)
```

### Common umask Values

| umask | Files | Dirs | Use Case |
|-------|-------|------|----------|
| `0000` | 666 (rw-rw-rw-) | 777 (rwxrwxrwx) | Complete open — everyone can do everything |
| `0002` | 664 (rw-rw-r--) | 775 (rwxrwxr-x) | Shared projects — group can write |
| `0022` | 644 (rw-r--r--) | 755 (rwxr-xr-x) | Default — group can read but not write |
| `0027` | 640 (rw-r-----) | 750 (rwxr-x---) | Restricted — group can read, others nothing |
| `0077` | 600 (rw-------) | 700 (rwx------) | Private — only owner can do anything |

```bash
# Set umask temporarily
umask 0027

# Touch a file and check
touch test.txt
ls -l test.txt
# -rw-r----- 1 alice alice 0 Jan 15 10:30 test.txt

# Set permanently in ~/.bashrc or ~/.profile
echo "umask 0027" >> ~/.profile
```

> 💡 On shared systems, set `umask 0027` to prevent other users from reading your files by default.

---

## 🔍 Section 13: Access Control Lists (ACLs) — Fine-Grained Permissions

Standard permissions only give you three groups: owner, group, others. **ACLs** let you give permissions to specific users or groups.

### Check if ACLs Are Supported

```bash
# Filesystem must be mounted with 'acl'
mount | grep " acl "

# Check filesystem type (ext4, xfs usually support it by default)
df -T /home
```

### ACL Commands

```bash
# View ACL of a file
getfacl file.txt

# Set ACL: give alice read/write access
setfacl -m u:alice:rw file.txt

# Set ACL: give developers group read/execute
setfacl -m g:developers:rx file.txt

# Remove a specific ACL entry
setfacl -x u:alice file.txt

# Remove ALL ACL entries (back to standard permissions)
setfacl -b file.txt

# Apply ACL recursively to a directory
setfacl -Rm u:alice:rwx /shared/project

# Set default ACL — new files inherit this
setfacl -dm u:alice:rwx /shared/project
# Now every file/dir created INSIDE /shared/project gets ACL for alice
```

### How ACLs Show in ls -l

When a file has ACLs, `ls -l` shows a `+` at the end of the permission string:

```bash
-rw-rw-r--+ 1 alice alice 0 Jan 15 10:30 file.txt
#           ↑
#           + means ACLs are set
```

### Real ACL Example — Shared Project Directory

```bash
sudo mkdir -p /shared/project
sudo chown root:project /shared/project
sudo chmod 770 /shared/project

# Give alice (who is not in 'project' group) full access
sudo setfacl -m u:alice:rwx /shared/project

# Give bob read-only access
sudo setfacl -m u:bob:r-x /shared/project

# Verify
getfacl /shared/project
# # file: shared/project
# # owner: root
# # group: project
# user::rwx
# user:alice:rwx
# user:bob:r-x
# group::rwx
# mask::rwx
# other::---
```

---

## 🔍 Section 14: The Complete Permission Checklist — Troubleshooting

When a user says "I can't access this file," follow this checklist in order:

```
1. Can they see the file?           ── Need r on the directory
2. Can they enter the directory?    ── Need x on the directory
3. Check each parent directory      ── All parents need x
4. Can they read the file?          ── Need r on the file
5. Can they write the file?         ── Need w on the file
6. Can they run the file?           ── Need x on the file
7. Are they the owner?              ── Check chown
8. Are they in the group?           ── Check groups + /etc/group
9. Is there an ACL?                 ── Check getfacl
10. Is SELinux/AppArmor blocking?   ── Check audit log (future parts)
```

### Common Permission Problems

```bash
# Problem: "I copied a file but can't read it"
# Solution: Check parent directory permissions, not just the file

# Problem: "I added user to group but they still can't access"
# Solution: User must LOG OUT and back in for group changes to take effect
# Faster: exec su - $USER   (or newgrp)

# Problem: "My script won't run"
./script.sh
# -bash: ./script.sh: Permission denied
chmod +x script.sh

# Problem: "sudo says I'm not in the sudoers file"
# Solution: Someone must add you using visudo

# Problem: "I can't delete my own file from /tmp"
# Solution: Sticky bit. Only owner can delete.
```

---

## 💻 PRACTICE SECTION — 20 Hands-On Exercises

> Type every command yourself. Create a practice user to avoid affecting real accounts.

### Level 1 Practices — Permission Fundamentals

---

### ✅ Practice 1: Read Permission Strings

```bash
cd /tmp && mkdir -p perm_practice && cd perm_practice

# Create some test files
touch file1.txt file2.sh
mkdir dir1

# Give them different permissions
chmod 644 file1.txt
chmod 755 file2.sh
chmod 700 dir1

ls -la

# For each file, write down:
# - What is the file type?
# - What can the owner do?
# - What can the group do?
# - What can others do?
```

---

### ✅ Practice 2: Experiment with Permissions

```bash
cd /tmp/perm_practice

# Remove read permission from a file
chmod 200 test.txt
cat test.txt         # What happens?

# Add read back
chmod 400 test.txt
cat test.txt         # Now?

# Remove execute from a directory
chmod 644 dir1
ls dir1              # Can you list it?
cd dir1              # Can you enter it?
```

---

### ✅ Practice 3: Permission Conversion Drills

Convert these manually, then verify with `chmod`:

```bash
# Symbolic to Numeric
# u=rwx,g=rx,o=   =  ?
# u=rw,g=r,o=r    =  ?
# u=rwx,g=rwx,o=  =  ?

# Numeric to Symbolic
# 751 = ?
# 640 = ?
# 555 = ?

# Test your answers:
touch test_perm
chmod 751 test_perm
ls -l test_perm
```

---

### ✅ Practice 4: Directory vs File Permissions

```bash
cd /tmp/perm_practice

mkdir dir_test
cd dir_test
touch secret.txt

# Go back and remove execute from parent
cd ..
chmod 644 dir_test
ls -l dir_test       # Can you see files?
ls dir_test          # Can you list them?
cat dir_test/secret.txt  # Can you read the file?

# Now add execute back
chmod 755 dir_test
cat dir_test/secret.txt  # Works now?

# Conclusion: x on directory is essential
```

---

### ✅ Practice 5: Create Practice Users

```bash
# Create two practice users
sudo useradd -m -s /bin/bash student1
sudo useradd -m -s /bin/bash student2

# Set passwords
echo "student1:password123" | sudo chpasswd
echo "student2:password123" | sudo chpasswd

# Verify
id student1
id student2
```

---

### ✅ Practice 6: Test File Isolation

```bash
# As student1, create a file
sudo -u student1 bash -c 'echo "Secret data" > /tmp/student1_file.txt'
sudo -u student1 bash -c 'chmod 600 /tmp/student1_file.txt'

# As student2, try to read it
sudo -u student2 bash -c 'cat /tmp/student1_file.txt'
# Should fail — Permission denied

# As student1, allow student2 to read it
sudo -u student1 bash -c 'chmod 644 /tmp/student1_file.txt'

# As student2, try again
sudo -u student2 bash -c 'cat /tmp/student1_file.txt'
# Should work now
```

---

### ✅ Practice 7: Read /etc/passwd and /etc/shadow

```bash
# Anatomy of /etc/passwd
head -5 /etc/passwd
tail -5 /etc/passwd

# Count total users
wc -l /etc/passwd

# Count regular users (UID >= 1000)
awk -F: '$3 >= 1000 {print $1}' /etc/passwd | wc -l

# Try reading shadow without sudo
cat /etc/shadow    # Permission denied

# Read with sudo
sudo head -5 /etc/shadow
```

---

### ✅ Practice 8: Explore /etc/skel

```bash
# See skeleton directory
ls -la /etc/skel/

# Create a new user and see their home
sudo useradd -m testuser
ls -la /home/testuser/
# Notice: same files as /etc/skel/

# Clean up
sudo userdel -r testuser
```

---

### Level 2 Practices — User & Group Administration

---

### ✅ Practice 9: Create Users with Specific Settings

```bash
# Create a user with custom UID, group, and settings
sudo groupadd developers
sudo useradd -u 3000 -g developers -G sudo -c "John Developer" -m -s /bin/bash johnd

# Verify
id johnd
# uid=3000(johnd) gid=3001(developers) groups=3001(developers),27(sudo)

grep johnd /etc/passwd
grep johnd /etc/shadow
```

---

### ✅ Practice 10: Lock and Unlock Users

```bash
# Lock the user
sudo passwd -l johnd

# Verify in shadow
sudo grep johnd /etc/shadow
# Notice the ! prefix on the password hash

# Try to switch to the user (should fail)
sudo -u johnd whoami

# Unlock
sudo passwd -u johnd

# Now it works
sudo -u johnd whoami
```

---

### ✅ Practice 11: Force Password Change on Next Login

```bash
# Expire password
sudo passwd -e johnd

# Check status
sudo passwd -S johnd

# When johnd logs in next, they will be forced to change password
```

---

### ✅ Practice 12: Modify a User

```bash
# Add johnd to more groups
sudo usermod -aG docker johnd
id johnd
# Notice docker group added

# Change description
sudo usermod -c "John Developer (Senior)" johnd
grep johnd /etc/passwd

# Change shell
sudo usermod -s /bin/zsh johnd
grep johnd /etc/passwd
```

---

### ✅ Practice 13: Group Management

```bash
# Create groups
sudo groupadd project-alpha
sudo groupadd project-beta

# Add members
sudo gpasswd -a student1 project-alpha
sudo gpasswd -a student2 project-beta
sudo gpasswd -a student1 project-beta

# Check membership
grep project-alpha /etc/group
grep project-beta /etc/group

# See member's groups
groups student1
groups student2
```

---

### ✅ Practice 14: Explore chown and chgrp

```bash
cd /tmp/perm_practice

# Create a file as your normal user
touch owned_by_me.txt
ls -l owned_by_me.txt

# Change group (works because you own it)
chgrp student1 owned_by_me.txt
ls -l owned_by_me.txt

# Try to change owner to someone else (should fail)
chown student2 owned_by_me.txt
# chown: changing ownership of 'owned_by_me.txt': Operation not permitted

# Use sudo (works)
sudo chown student2 owned_by_me.txt
ls -l owned_by_me.txt
```

---

### Level 3 Practices — Advanced Access Control

---

### ✅ Practice 15: SUID Exploration

```bash
# Find all SUID binaries on your system
find /usr/bin /usr/sbin -perm -4000 -type f 2>/dev/null

# Look at passwd specifically
ls -l /usr/bin/passwd
# Notice the 's' in owner position

# See how SUID works
echo "My uid is: $(id -u)"
# Now run passwd — it needs to write to /etc/shadow as root
# The SUID bit makes this possible
```

---

### ✅ Practice 16: SGID on Directories

```bash
cd /tmp/perm_practice

# Create a shared directory with SGID
sudo mkdir sgid_test
sudo chgrp project-alpha sgid_test
sudo chmod g+s sgid_test
sudo chmod 770 sgid_test

# As student1, create a file inside
sudo -u student1 touch sgid_test/file_from_student1.txt
ls -l sgid_test/
# Notice: group is 'project-alpha', NOT student1's primary group

# As student2, can they write?
sudo -u student2 touch sgid_test/file_from_student2.txt
ls -l sgid_test/
```

---

### ✅ Practice 17: Sticky Bit Demo

```bash
cd /tmp

# Create a shared directory without sticky bit
mkdir nosticky
chmod 777 nosticky

# As student1, create a file
sudo -u student1 touch nosticky/student1.txt

# As student2, try to delete student1's file
sudo -u student2 rm nosticky/student1.txt
# This WORKS — anyone can delete anyone's files in world-writable dirs

# Now create with sticky bit
mkdir withsticky
chmod 1777 withsticky

# As student1, create a file
sudo -u student1 touch withsticky/student1.txt

# As student2, try to delete it
sudo -u student2 rm withsticky/student1.txt
# This FAILS — sticky bit protects it
```

---

### ✅ Practice 18: umask Experiments

```bash
cd /tmp/perm_practice

# Check current umask
umask

# Create a file with default umask
touch default_perm.txt
ls -l default_perm.txt

# Change umask and create another
umask 0077
touch private.txt
ls -l private.txt

umask 0002
touch shared.txt
ls -l shared.txt

# Restore normal
umask 0022
```

---

### ✅ Practice 19: ACL Practice

```bash
cd /tmp/perm_practice

# Create a file
touch acl_test.txt
chmod 640 acl_test.txt
ls -l acl_test.txt    # No + yet

# Give student1 specific access
setfacl -m u:student1:rwx acl_test.txt
ls -l acl_test.txt    # + appears!

# View the ACL
getfacl acl_test.txt

# Test as student1
sudo -u student1 bash -c 'echo "ACL works!" >> /tmp/perm_practice/acl_test.txt'
sudo -u student1 bash -c 'cat /tmp/perm_practice/acl_test.txt'
```

---

### ✅ Practice 20: Real SysAdmin Scenario — Setting Up a Shared Project Directory

```bash
# Create the project directory structure
sudo mkdir -p /srv/projects/alpha/{src,logs,docs,backup}
sudo chown -R root:project-alpha /srv/projects/alpha

# Set permissions: owner and group full access, others nothing
sudo chmod -R 770 /srv/projects/alpha

# Set SGID so all files inherit group
sudo chmod g+s /srv/projects/alpha

# Set default ACL so new files also get the right permissions
sudo setfacl -Rdm g:project-alpha:rwx /srv/projects/alpha
sudo setfacl -Rm g:project-alpha:rwx /srv/projects/alpha

# Give a specific user (not in group) access
sudo setfacl -Rm u:student1:rx /srv/projects/alpha

# Verify everything
ls -la /srv/projects/alpha
getfacl /srv/projects/alpha

# Test as different users
sudo -u student1 touch /srv/projects/alpha/src/test.txt
sudo -u student2 ls /srv/projects/alpha/src
```

---

## 🧠 Deep Understanding — How Permissions Really Work

### The Real Identity Check

When a process tries to access a file, Linux performs this check:

```
Is the process running as UID 0 (root)?
  ├── YES → Permission GRANTED (root can do anything)
  └── NO →
      Is the process UID the same as the file owner?
        ├── YES → Apply USER permission bits
        └── NO →
            Is the process GID (or any supplementary GID) in the file's group?
              ├── YES → Apply GROUP permission bits
              └── NO → Apply OTHER permission bits
```

It stops at the **first** match. If you are the owner, group permissions are **ignored** entirely.

> 💡 **Real implication:** If owner has `r--` and group has `rwx`, the owner cannot write to the file even though their group can. The owner match was found first.

### The inode — Where Permissions Live

Permissions are stored in the **inode**, not in the filename. This is why:
- Hard links cannot have different permissions — they share the same inode
- Moving a file (same filesystem) preserves permissions — the inode didn't change
- Renaming a file preserves permissions — the inode didn't change

```bash
# Check inode number and see permissions live there
ls -li /etc/hosts
# 1234567 -rw-r--r-- 1 root root 221 ...
# ↑
# inode number

# Two names for the same inode have the same permissions
ln /etc/hosts /tmp/hosts_copy
ls -li /etc/hosts /tmp/hosts_copy
# Same inode = same permissions
```

### Why sudo Doesn't Need Passwords Sometimes

Look at `/etc/sudoers.d/`:

```bash
ls -la /etc/sudoers.d/
```

Some distros put a file like `90-cloud-init-users` that grants passwordless sudo to the first user. This is why your admin user can run sudo without a password.

### The Security Triad

Every permission decision balances three things:

```
Confidentiality ─── Who can READ this?
     ↑
Integrity     ─── Who can WRITE this?
     ↑
Availability  ─── Who can EXECUTE/ACCESS this?
```

As a sysadmin, every file you create should make you ask: "Who should read this? Who should change this? Who should run this?"

---

## 📋 Summary — Complete Command Reference for Part 3

### Level 1: Basic — Permission Fundamentals

**Reading Permissions**
| Command | What It Does |
|---------|-------------|
| `ls -l file` | Show permissions of file |
| `ls -ld dir` | Show permissions of directory itself |

**Changing Permissions (chmod)**
| Command | What It Does |
|---------|-------------|
| `chmod u+x file` | Add execute for owner |
| `chmod go-w file` | Remove write for group and others |
| `chmod 755 file` | Set to rwxr-xr-x (numeric) |
| `chmod -R 755 dir` | Recursively change directory |

**Changing Ownership**
| Command | What It Does |
|---------|-------------|
| `chown user file` | Change owner |
| `chown user:group file` | Change owner and group |
| `chown :group file` | Change only group |
| `chgrp group file` | Change group |
| `chown -R user dir` | Recursively change |

### Level 2: Intermediary — User & Group Administration

**User Management**
| Command | What It Does |
|---------|-------------|
| `useradd -m -s /bin/bash bob` | Create user with home and shell |
| `useradd -D` | Show default user creation settings |
| `usermod -aG sudo bob` | Add user to supplementary group |
| `usermod -L bob` | Lock user account |
| `usermod -U bob` | Unlock user account |
| `usermod -l newname bob` | Change username |
| `userdel -r bob` | Delete user and home directory |
| `passwd bob` | Set/change password |
| `passwd -l bob` | Lock password |
| `passwd -e bob` | Expire password (force change) |
| `passwd -S bob` | Show password status |

**Group Management**
| Command | What It Does |
|---------|-------------|
| `groupadd developers` | Create group |
| `groupmod -n newname oldname` | Rename group |
| `groupdel developers` | Delete group |
| `gpasswd -a user group` | Add user to group |
| `gpasswd -d user group` | Remove user from group |
| `groups user` | Show user's groups |
| `id user` | Show UID, GID, and all groups |
| `newgrp group` | Temporarily change primary group |

**Sudo**
| Command | What It Does |
|---------|-------------|
| `sudo command` | Run command as root |
| `sudo -u user command` | Run command as another user |
| `sudo -l` | List allowed commands |
| `sudo -s` | Root shell (current dir) |
| `sudo -i` | Root login shell (root's env) |
| `sudo -e file` | Edit file as root safely |
| `visudo` | Safely edit /etc/sudoers |

### Level 3: Advanced — Advanced Access Control

**Special Permissions**
| Command | What It Does |
|---------|-------------|
| `chmod u+s file` | Set SUID |
| `chmod g+s dir` | Set SGID on directory |
| `chmod o+t dir` | Set Sticky Bit |
| `chmod 4755 file` | Set SUID (numeric) |
| `chmod 2755 dir` | Set SGID (numeric) |
| `chmod 1777 dir` | Set Sticky Bit (numeric) |
| `find / -perm -4000` | Find all SUID files |

**Default Permissions (umask)**
| Command | What It Does |
|---------|-------------|
| `umask` | Show current umask |
| `umask 0027` | Set umask temporarily |
| `umask 0027` in `~/.profile` | Set umask permanently |

**ACLs**
| Command | What It Does |
|---------|-------------|
| `getfacl file` | View ACL |
| `setfacl -m u:user:rwx file` | Give user specific access |
| `setfacl -m g:group:rx file` | Give group specific access |
| `setfacl -x u:user file` | Remove user's ACL entry |
| `setfacl -b file` | Remove all ACLs |
| `setfacl -R -m u:user:rwx dir` | Recursively apply ACL |
| `setfacl -dm g:group:rwx dir` | Set default ACL for new files |

---

## 🚀 What's Coming in Part 4

**Part 4: Text Editors — Vim, Nano, and Why They Matter**

You will learn:
- Why every sysadmin MUST know a terminal text editor
- Vim from zero — mode-based editing explained
- Nano for quick edits
- Configuring your editor
- Searching, replacing, and navigating large files
- 15 hands-on practices

---

## 📝 Self-Test — Can You Answer These?

1. What do `r`, `w`, and `x` mean on a **directory** (not a file)?
2. Convert `-rwxr-x---` to numeric permissions.
3. Convert `751` to symbolic permissions.
4. What does `chmod u+s` do? When would you use it?
5. What is the purpose of the Sticky Bit? Where do you see it by default?
6. What is the difference between `/etc/passwd` and `/etc/shadow`?
7. How do you add a user to the `sudo` group without removing them from other groups?
8. What happens when you set SGID on a directory?
9. Why can a regular user run `passwd` even though it writes to root-owned `/etc/shadow`?
10. What is `umask 0027` in terms of resulting file and directory permissions?
11. How do you view the ACL of a file?
12. How would you give user `bob` read/write access to a file without changing its owner or group?
13. What is the difference between `sudo -s` and `sudo -i`?
14. A user reports: "I was added to the `developers` group but I still can't access the shared directory." What is the most likely cause?
15. How do you find all files on the system with the SUID bit set?

**Score:** 12/15 correct = ready for Part 4.

---

*Linux SysAdmin Course | Part 3 of ∞ | Reverse Engineering Approach*
*Previous → Part 2: Mastering the Terminal — Navigation, Files & Directories*
*Next → Part 4: Text Editors — Vim, Nano, and Why They Matter*

[← Previous](part2.md) | [Next →](part4.md)
