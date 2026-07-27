## 💻 PRACTICE SECTION — 10 Hands-On Exercises

> Do every single one. Typing commands yourself is 10x better than reading.

### Level 1 Practices — Linux Foundations

---

### ✅ Practice 1: Read Your Prompt

Open a terminal. Look at your prompt.

```bash
# What do you see? Example:
john@ubuntu:~$
```

**Questions to answer:**
- What is your username?
- What is your hostname?
- Are you root or normal user? ($ = normal, # = root)

---

### ✅ Practice 2: Explore Kernel and System Info

```bash
# See your Linux kernel version
uname -r

# See all system info at once
uname -a

# See Linux distribution name
cat /etc/os-release

# See how long the system has been running
uptime
```

**What to look for:**
- Your kernel version number
- Your Linux distribution name and version
- How many days/hours your system has been running

---

### Level 2 Practices — Navigating the System

---

### ✅ Practice 3: Navigate the File System

```bash
# Show your current location
pwd

# Go to root of the filesystem
cd /

# List everything at root level
ls

# List with details
ls -l

# Go back to your home directory
cd ~

# Confirm you're home
pwd
```

**Expected output of `pwd` at home:**
```
/home/yourusername
```

---

### ✅ Practice 4: Explore Key Directories

```bash
# Look inside /etc (system configs)
ls /etc | head -20

# Look inside /var/log (system logs)
ls /var/log

# Look inside /dev (hardware devices)
ls /dev | head -20

# Look inside /proc (live system info)
ls /proc | head -30
```

> 💡 The `| head -20` part limits output to 20 lines so your screen doesn't flood.

---

### ✅ Practice 5: Find Out Who You Are

```bash
# Your username
whoami

# Full identity info
id

# All logged-in users right now
who

# More detailed login info
w
```

---

### ✅ Practice 6: Read a Real System File

```bash
# Read your system's hostname
cat /etc/hostname

# Read the system's host list
cat /etc/hosts

# Read OS version info
cat /etc/os-release
```

> 💡 `cat` = "concatenate" — it prints the content of a file to screen. You'll use this thousands of times.

---

### ✅ Practice 7: Look at a Running Process — The Kernel in Action

```bash
# See your current CPU info (the kernel reporting hardware)
cat /proc/cpuinfo | head -30

# See memory info
cat /proc/meminfo | head -10

# See your current process ID
echo $$
cat /proc/$$/status | head -10
```

> 🔍 **Reverse Engineering Insight:** `/proc/$$` is a folder with info about YOUR current shell process. You just accessed live kernel data through a file!

---

### ✅ Practice 8: Understand the Shell

```bash
# Which shell are you using?
echo $SHELL

# What version of bash?
bash --version

# See all environment variables (the shell's memory)
env | head -20

# See your PATH (where the shell looks for commands)
echo $PATH
```

---

### ✅ Practice 9: Get Help — The Right Way

```bash
# Get help for any command using man (manual)
man ls

# (Press q to quit the manual)

# Quick help with --help
ls --help

# Even shorter summary with tldr (if installed)
# tldr ls
```

> 💡 Professional sysadmins use `man` constantly. Get comfortable with it now.

---

### ✅ Practice 10: Reverse Engineer Your Own Session

```bash
# When did the system last boot?
who -b

# What shell processes are running?
ps -p $$

# What is the full path of the bash command?
which bash
type bash

# How many users are defined on this system?
cat /etc/passwd | wc -l

# See the first 5 user accounts
head -5 /etc/passwd
```

**Explain to yourself:** What is `/etc/passwd`? It is the file where Linux stores all user accounts. Each line is one user. You just counted how many users exist!

---



---

[← Previous](10-section-7-your-first-terminal.md) | [↑ Index](index.md) | [Next →](12-level-3-advanced-how-linux.md)
