# 🐧 Linux System Administrator — Complete Course
## Part 4 of ∞: Text Editors — Vim, Nano, and Why They Matter

---

> **Reverse Engineering Approach:** Most people think a text editor is just a tool for typing. In reality, it is the single most-used application in a sysadmin's life. Every config file, every script, every log analysis passes through an editor. We will start by asking: *What makes a terminal text editor different from a GUI editor?* Then we will use that understanding to master Vim, Nano, and their ecosystem.

---

## 🎯 What You Will Achieve in Part 4

| Level | Focus | What You'll Learn |
|-------|-------|------------------|
| **⭐ Level 1: Basic** | Getting Started with Terminal Editors | Why terminal editors matter, Nano basics, Vim survival (open, edit, save, quit) |
| **⭐ Level 2: Intermediary** | Efficient Editing | Vim navigation, cut/copy/paste, search & replace, visual mode, .vimrc config, crash recovery |
| **⭐ Level 3: Advanced** | Professional Editor Workflows | Multi-file editing, split windows, tabs, diff mode, shell commands from Vim |

---

## ⭐ Level 1: Basic — Getting Started with Terminal Editors

![Vim logo — the professional's text editor](https://upload.wikimedia.org/wikipedia/commons/9/9f/Vimlogo.svg)
*Vim logo. Wikimedia Commons, GPL.*

> **Level 1 Goal:** Understand why terminal editors are essential, edit files with Nano, and survive your first Vim session — open, edit, save, quit without panic.

---



## 🔍 Section 1: Why Terminal Text Editors?

A GUI text editor (like VS Code, Sublime Text, or Gedit) requires a graphical desktop. But as a sysadmin, you often work on:

- **Remote servers** over SSH (no screen, no desktop)
- **Minimal installations** (no GUI installed)
- **Recovery environments** (single-user mode, initramfs)
- **Embedded systems** (no display at all)

In all these scenarios, a **terminal text editor** is your only option.

### The Two Choices

| Editor | Philosophy | Best For |
|--------|-----------|----------|
| **Vim** | Modal editing — keys do different things in different modes | Heavy file editing, coding, scripting, any serious work |
| **Nano** | Modeless — keys type characters directly | Quick edits, beginners, simple config changes |

> 💡 Learn **both**. Use Nano when you need to change one line in a config file. Use Vim when you need to write a script or edit for more than 30 seconds.

---

## 🔍 Section 2: Nano — The Simple Editor

Nano is installed on nearly every Linux system. It shows a menu at the bottom and behaves like a normal text editor.

### Opening Files

```bash
nano /etc/hosts
nano ~/.bashrc
nano +25 file.txt        # Open at line 25
```

### The Bottom Menu

When you open Nano, you see this at the bottom:

```
^G Get Help  ^O Write Out  ^W Where Is  ^K Cut Text  ^J Justify
^X Exit      ^R Read File  ^\ Replace   ^U Uncut Text ^T To Spell
```

The `^` means **Ctrl**. So `^X` means press `Ctrl` + `X`.

### Essential Nano Commands

| Key | Action |
|-----|--------|
| `Ctrl+O` | Save (Write Out) — then press Enter to confirm |
| `Ctrl+X` | Exit — asks to save if changes exist |
| `Ctrl+W` | Search (Where Is) — type term, press Enter |
| `Ctrl+\` | Search and Replace |
| `Ctrl+K` | Cut current line (store in buffer) |
| `Ctrl+U` | Paste (Uncut) from buffer |
| `Ctrl+G` | Show help |
| `Ctrl+A` | Go to beginning of line |
| `Ctrl+E` | Go to end of line |
| `Ctrl+Y` | Previous page |
| `Ctrl+V` | Next page |
| `Ctrl+_` | Go to line number |
| `Alt+A` | Start selecting text (set mark) |
| `Alt+6` | Copy selected text |
| `Alt+U` | Undo |
| `Alt+E` | Redo |

### What Happens When You Save

```bash
# Nano creates a temporary file, writes to it, then replaces the original
# This preserves atomic writes — the file is never in a half-written state
```

### When to Use Nano

```bash
# Quick config edit — 5 seconds
sudo nano /etc/ssh/sshd_config
# Change one line: Port 2222
# Ctrl+O, Ctrl+X
# Done.

# Quick script touch-up
nano ~/deploy.sh
```

> 💡 Nano is **always available**. If you SSH into a random server and need to change a config file, Nano will work. Vim might not be installed.

---

## 🔍 Section 3: Vim — The Professional's Editor

Vim (Vi IMproved) is a **modal editor**. This is the single most important concept to understand.

### The Biggest Mistake Beginners Make

```bash
vim file.txt
# They start typing... nothing appears
# Or: "i i i i i" because they heard you need to press 'i'
# Or: panic and force quit
```

The problem: Vim is in **Normal mode** by default. In Normal mode, every key is a **command**, not a character.

### The Three Essential Modes

```
┌─────────────────────────────────────────────────────────┐
│                    NORMAL MODE                           │
│   (default — keys are commands, not typing)              │
│                                                          │
│   Press i  ─────────────────────────────────────────    │
│   to enter              Press Esc to return              │
│   INSERT MODE ───────────────────────► NORMAL MODE       │
│   (keys type text)          ◄──────── Press Esc          │
│                                                          │
│   Press :  ─────────────────────────────────────────    │
│   to enter              Press Esc to return              │
│   COMMAND MODE ──────────────────────► NORMAL MODE       │
│   (save, quit, search...)   ◄──────── Press Esc          │
└─────────────────────────────────────────────────────────┘
```

### Mode 1: Normal Mode — You Start Here

Keys move the cursor and manipulate text. This is where you spend most of your Vim time.

### Mode 2: Insert Mode — Where You Type Text

Press `i` to enter. Now keys type characters like a normal editor.

### Mode 3: Command Mode — Where You Save, Quit, Search

Press `:` to enter. Now you type commands like `w` (save), `q` (quit), or `/searchterm`.

---

## 🔍 Section 4: Vim Survival Guide — The Only 7 Things You Need to Start

```bash
# Open a file
vim file.txt

# 1. QUIT without saving
# Press Esc to make sure you're in Normal mode
# Then type:
:q!
# (colon, q, bang, Enter)

# 2. SAVE and QUIT
:wq
# (colon, w, q, Enter)

# 3. SAVE (without quitting)
:w

# 4. ENTER INSERT MODE (start typing)
i

# 5. BACK to NORMAL MODE
Esc

# 6. UNDO
u      (in Normal mode)

# 7. SEARCH
/searchterm    (type this, then press Enter)
n              (next match)
N              (previous match)
```

Write these on a sticky note. Refer to them until they become reflex.

---

## ⭐ Level 2: Intermediary — Efficient Editing

![Vim screenshot showing keyword completion and syntax highlighting](https://upload.wikimedia.org/wikipedia/commons/2/28/Vim.png)
*Screenshot of graphical Vim (gvim) showing keyword completion by Ehamberg. Wikimedia Commons, GPL.*

> **Level 2 Goal:** Navigate files efficiently without arrow keys, master cut/copy/paste, search and replace with regex, use visual mode, configure Vim with .vimrc, and recover from crashes.

---

## 🔍 Section 5: Vim Navigation — Moving Without the Arrow Keys

Professional Vim users **never** use arrow keys. They use `h`, `j`, `k`, `l`.

```bash
# Basic movement (keep fingers on home row)
h       Left
j       Down
k       Up
l       Right

# Word movement
w       Forward one word
b       Back one word
e       End of current word

# Line movement
0       Beginning of line
$       End of line
^       First non-whitespace character

# Screen movement
Ctrl+f  Page down (forward)
Ctrl+b  Page up (back)
H       Top of screen (High)
M       Middle of screen
L       Bottom of screen (Low)

# File movement
gg      Beginning of file
G       End of file
50G     Go to line 50
```

### Why This Matters

```bash
# Compare:
# Arrow key user moves from line 100 to line 200:
# Press down arrow 100 times   (slow)

# Vim user:
200G     (instant)

# Or from the middle of a word to the end:
# Arrow key user: right-arrow, right-arrow... (6+ presses)
# Vim user:
e        (1 press)
```

---

## 🔍 Section 6: Vim Editing — Cut, Copy, Paste, Delete

In Vim, delete is also **cut** — it stores text in a register.

### Deleting (Cutting)

```bash
x       Delete character under cursor
dd      Delete (cut) current line
dw      Delete from cursor to end of word
d$      Delete from cursor to end of line
d0      Delete from beginning of line to cursor
dG      Delete from cursor to end of file
dgg     Delete from beginning of file to cursor
```

### Copying (Yanking)

```bash
yy      Yank (copy) current line
yw      Yank current word
y$      Yank to end of line
```

### Pasting

```bash
p       Paste below current line
P       Paste above current line
```

### Putting It Together

```bash
# Move a line from here to there:
dd      # Cut the line
j       # Go down
p       # Paste it

# Copy a line and paste it elsewhere:
yy      # Copy the line
/target # Search for "target"
p       # Paste it

# Delete 5 lines:
5dd

# Copy 3 words:
3yw

# Delete inside parentheses:
di(     # Delete everything inside ( )
da(     # Delete everything including ( )
```

---

## 🔍 Section 7: Vim Search and Replace

### Searching

```bash
/error       # Search forward for "error"
?error       # Search backward for "error"
n            # Next match
N            # Previous match

# Case-insensitive search
/error\c     # \c makes search case-insensitive

# Highlight all matches
:set hlsearch
# :nohlsearch  to remove highlights temporarily
```

### Search and Replace

```bash
# Replace first match on current line
:s/old/new

# Replace all matches on current line
:s/old/new/g

# Replace all matches in entire file
:%s/old/new/g

# Replace with confirmation (ask each time)
:%s/old/new/gc

# Replace only in lines 10-20
:10,20s/old/new/g

# Replace using regex (wildcards)
:%s/foo.*bar/new/g
```

### The Most Common SysAdmin Find-and-Replace

```bash
# Change a port number in a config file
:%s/Port 22/Port 2222/g

# Replace all IP addresses
:%s/192.168.1.100/192.168.2.100/g

# Add a prefix to every line
:%s/^/PREFIX/

# Add a suffix to every line
:%s/$/SUFFIX/
```

---

## 🔍 Section 8: Vim Visual Mode — Selecting Text

Visual mode lets you select text visually before acting on it.

```bash
v        Start visual mode (character-wise)
V        Start visual mode (line-wise)
Ctrl+v   Start visual block mode (column-wise)

# After selecting, type command:
d        Delete selected
y        Copy (yank) selected
c        Change selected (delete + insert mode)
>        Indent right
<        Indent left
~        Toggle case
```

### Visual Block Mode — Extremely Powerful

```bash
# Add a comment to 10 lines:
# 1. Ctrl+v at the beginning of line 1
# 2. Move down 9 lines (or type 9j)
# 3. Press I (capital i)
# 4. Type #
# 5. Press Esc — all 10 lines get # at the beginning

# Remove the first 5 characters from 20 lines:
# 1. Ctrl+v at column 1 of line 1
# 2. Move right 5 columns
# 3. Move down 19 lines
# 4. Press d — characters are deleted from all lines
```

---

## 🔍 Section 9: Vim Configuration — .vimrc

Vim's behavior is controlled by `~/.vimrc`. Here is a professional starting config:

```vim
" ~/.vimrc — Professional sysadmin configuration
" This file controls how Vim behaves

" Essentials
set nocompatible              " Use Vim settings, not Vi
syntax on                     " Enable syntax highlighting
set number                    " Show line numbers
set ruler                     " Show cursor position
set showcmd                   " Show partial commands

" Indentation
set tabstop=4                 " Tab = 4 spaces
set shiftwidth=4              " Indent = 4 spaces
set expandtab                 " Use spaces, not tabs
set autoindent                " Copy indent from current line

" Search
set incsearch                 " Search as you type
set ignorecase                " Case-insensitive search
set smartcase                 " Case-sensitive if uppercase in search
set hlsearch                  " Highlight matches

" Editing
set backspace=indent,eol,start " Make backspace work normally
set showmatch                 " Show matching brackets

" Files
set fileformats=unix,dos,mac  " Handle different line endings
set encoding=utf-8

" Visual
set cursorline                " Highlight current line
set wildmenu                  " Tab completion for commands

" Backup (professionals keep backups)
set backupdir=~/.vim/backup   " Backup directory
set directory=~/.vim/swap     " Swap files directory
set undodir=~/.vim/undo       " Persistent undo
```

Apply changes without restarting:

```bash
:so %      # Source (reload) the current file
```

---

## 🔍 Section 10: Vim Crash Recovery

Vim saves swap files to protect against crashes.

```bash
# When Vim crashes or SSH disconnects:
# You will see this message when reopening:
# "Swap file *.swp already exists!"
# Options:
# [O]pen Read-Only   — view the file
# [E]dit anyway      — edit despite swap file
# [R]ecover          — recover from swap
# [D]elete it        — delete swap file (if you're sure)
# [Q]uit             — quit

# Manual recovery:
vim -r file.txt      # Recover from swap
vim -r               # List all recoverable files

# After recovery, clean up the swap files:
ls -la ~/.vim/swap/   # If you set backupdir
rm ~/.vim/swap/*      # Clean old swap files
```

---

## ⭐ Level 3: Advanced — Professional Editor Workflows

![Vim modes transition diagram showing relationships between Normal, Insert, Visual, and Command modes](https://rawgithub.com/darcyparker/1886716/raw/eab57dfe784f016085251771d65a75a471ca22d4/vimModeStateDiagram.svg)
*Vim modes transition diagram by Darcy Parker. CC BY.*

> **Level 3 Goal:** Master professional workflows — edit multiple files simultaneously, use split windows and tabs, diff files from within Vim, and execute shell commands without leaving the editor.

---

## 🔍 Section 11: Advanced Vim for SysAdmins

### Edit Multiple Files

```bash
# Open multiple files
vim file1.txt file2.txt file3.txt

# Navigate between them
:next       # Next file
:previous   # Previous file
:first      # First file
:last       # Last file

# List all open files
:files
# Output:
# 1 %a   "file1.txt"   line 1
# 2      "file2.txt"   line 0
# 3      "file3.txt"   line 0
```

### Split Windows

```bash
# Horizontal split
:split /etc/hosts
# or: :sp /etc/hosts

# Vertical split
:vsplit /etc/hostname
# or: :vs /etc/hostname

# Navigate between splits
Ctrl+w  then j    Move down
Ctrl+w  then k    Move up
Ctrl+w  then h    Move left
Ctrl+w  then l    Move right
Ctrl+w  then w    Cycle through splits

# Resize splits
Ctrl+w  =         Equal size
Ctrl+w  +         Increase height
Ctrl+w  -         Decrease height
```

### Tabs

```bash
:tabedit /etc/hosts    # Open in new tab
:tabnext               # Next tab
:tabprevious           # Previous tab
:tabclose              # Close current tab
gt                     # Go to next tab (Normal mode)
gT                     # Go to previous tab (Normal mode)
```

### Compare Two Files (Diff Mode)

```bash
vim -d file1.txt file2.txt
# or:
:diffsplit file2.txt    # From inside Vim

# Navigate differences
]c                      # Next difference
[c                      # Previous difference
dp                      # "diff put" — put changes into other file
do                      # "diff obtain" — get changes from other file
```

### Execute Shell Commands From Vim

```bash
# Run a command
:!ls -la

# Run a command on the current file
:!python3 %

# Insert command output into file
:r !date
# Inserts current date at cursor position

:r !ls /etc
# Inserts directory listing
```

---

## 🔍 Section 12: Nano vs Vim — When to Use Which

| Scenario | Editor |
|----------|--------|
| Change one line in a config file over SSH | **Nano** (faster to open/save) |
| Write a 100-line bash script | **Vim** (syntax highlighting, modal editing) |
| Emergency fix during an outage | **Nano** (less cognitive load under pressure) |
| Heavy text processing (column edits) | **Vim** (visual block mode is unique) |
| Editing a file you've never seen before | **Nano** (read the file, make quick change) |
| Writing code daily | **Vim** (learn it, invest the time) |
| Server with minimal tools installed | **Nano** (always available, vi is sometimes aliased) |

---

## 🔍 Section 13: Other Terminal Editors Worth Knowing

| Editor | Description |
|--------|-------------|
| **vi** | Original Vim. On every Unix system. No syntax highlighting. Learn it in case Vim isn't available. |
| **emacs** | The other major editor. Extremely powerful but heavy learning curve. |
| **neovim** | Modern Vim fork. Better plugin system, built-in terminal. |
| **micro** | Modern Nano-like editor with mouse support and syntax highlighting. |
| **ed** | The original line editor. One line at a time. Useful in scripts. |

```bash
# Using ed (surprisingly useful in scripts):
echo -e "a\nHello, World\n.\nw\nq" | ed file.txt
# This appends "Hello, World" to file.txt
```

---

## 💻 PRACTICE SECTION — 15 Hands-On Exercises

### Level 1 Practices — Getting Started with Terminal Editors

---

### ✅ Practice 1: Create a Practice Directory

```bash
mkdir -p ~/linux-course/part4
cd ~/linux-course/part4
echo "This is a test file." > test.txt
echo "Line 2" >> test.txt
echo "Line 3" >> test.txt
```

---

### ✅ Practice 2: Nano Basics

```bash
# Open test.txt in Nano
nano test.txt

# Inside Nano:
# 1. Type "Added with Nano" on line 4
# 2. Save: Ctrl+O, then Enter
# 3. Exit: Ctrl+X

# Verify:
cat test.txt
```

---

### ✅ Practice 3: Create a Config File With Nano

```bash
nano ~/linux-course/part4/app.conf

# Type this config:
# server_name=localhost
# port=8080
# debug=true
# log_level=info

# Save and exit. You just created a config file as a sysadmin would.
```

---

### ✅ Practice 4: Open Vim and Quit Without Panic

```bash
vim ~/linux-course/part4/test.txt

# Inside Vim:
# 1. Don't panic
# 2. Press : to enter command mode
# 3. Type q! (that's q + bang)
# 4. Press Enter
# You just quit Vim. Congratulations.
```

---

### ✅ Practice 5: Vim Navigation Drills

```bash
# Create a file with multiple lines
for i in $(seq 1 30); do echo "Line number $i"; done > ~/linux-course/part4/lines.txt

vim ~/linux-course/part4/lines.txt

# Practice these movements WITHOUT arrow keys:
# 1. Go to line 1     → gg
# 2. Go to line 30    → G
# 3. Go to line 15    → 15G
# 4. Go to word "number" → /number
# 5. Next match       → n
# 6. Previous match   → N
# 7. Go down 5 lines  → 5j
# 8. Go up 3 lines    → 3k
# 9. End of line      → $
# 10. Beginning of line → 0
```

---

### ✅ Practice 6: Vim Insert Mode Practice

```bash
vim ~/linux-course/part4/test.txt

# 1. Press i to enter insert mode
# 2. Type: "---START OF FILE---"
# 3. Press Enter
# 4. Press Esc to return to normal mode
# 5. Type :wq and press Enter
```

---

### Level 2 Practices — Efficient Editing

---

### ✅ Practice 7: Cut, Copy, Paste

```bash
vim ~/linux-course/part4/lines.txt

# 1. Move cursor to line 5
# 2. dd — delete (cut) the line
# 3. Move to line 10
# 4. p — paste below
# 5. Move to line 1
# 6. yy — copy line 1
# 7. Move to line 20
# 8. p — paste below

# Practice: move lines 1-5 to the end of the file
# 5dd  (cut 5 lines)
# G    (go to end)
# p    (paste)
```

---

### ✅ Practice 8: Search and Replace

```bash
vim ~/linux-course/part4/lines.txt

# Replace "Line" with "Row" on the current line only:
:s/Line/Row

# Replace "Line" with "Row" everywhere in the file:
:%s/Line/Row/g

# Replace with confirmation:
:%s/Row/Line/gc
# Press y to confirm each, n to skip
```

---

### ✅ Practice 9: Visual Block Mode

```bash
vim ~/linux-course/part4/lines.txt

# Add ">> " to the beginning of every line:
# 1. Ctrl+v at first character of line 1
# 2. Press G to jump to last line (selects all)
# 3. Press I (capital i)
# 4. Type ">> "
# 5. Press Esc

# Verify with :w and then :q
```

---

### ✅ Practice 10: Create a .vimrc

```bash
# Create the config directory
mkdir -p ~/.vim/backup ~/.vim/swap ~/.vim/undo

# Write the .vimrc
cat > ~/.vimrc << 'EOF'
set nocompatible
syntax on
set number
set ruler
set showcmd
set tabstop=4
set shiftwidth=4
set expandtab
set autoindent
set incsearch
set ignorecase
set smartcase
set hlsearch
set backspace=indent,eol,start
set showmatch
set fileformats=unix,dos,mac
set encoding=utf-8
set cursorline
set wildmenu
set backupdir=~/.vim/backup
set directory=~/.vim/swap
set undodir=~/.vim/undo
EOF

# Apply it immediately by opening Vim
vim ~/linux-course/part4/test.txt
# You should see line numbers and syntax highlighting
```

---

### ✅ Practice 11: Edit Multiple Files in Vim

```bash
cd ~/linux-course/part4

# Create two files
echo "File A content" > fileA.txt
echo "File B content" > fileB.txt

# Open both
vim fileA.txt fileB.txt

# In Vim:
:next          # Go to fileB
:previous      # Go back to fileA
:files         # List all buffers
```

---

### ✅ Practice 12: Split Windows

```bash
vim ~/linux-course/part4/lines.txt

# In Vim:
:split           # Split horizontally
:vs /etc/hosts   # Split vertically with another file

# Practice navigating:
# Ctrl+w then j   → down
# Ctrl+w then k   → up
# Ctrl+w then w   → cycle

# Close the split you don't need:
:q
```

---

### ✅ Practice 13: Diff Two Files

```bash
cd ~/linux-course/part4

# Create a modified version of the lines file
sed 's/Line/Entry/g' lines.txt > lines_modified.txt

# Diff the files in Vim
vim -d lines.txt lines_modified.txt

# In Vim:
# ]c  → next difference
# [c  → previous difference
# :q  → quit
```

---

### ✅ Practice 14: Run Shell Commands From Vim

```bash
vim

# From inside Vim (not editing any file):
:!ls -la /etc
# Output appears, press Enter to continue

:!date
# Shows current date

:r !date
# Inserts current date into the buffer

:r !ls /home
# Inserts list of home directories
```

---

### Level 3 Practices — Professional Editor Workflows

---

### ✅ Practice 15: Real SysAdmin Scenario — Edit a Config File

```bash
# Copy a real config file to practice on
cp /etc/ssh/sshd_config ~/linux-course/part4/

# Open it in Vim
vim ~/linux-course/part4/sshd_config

# Make these changes (this is what real sysadmins do):
# 1. Find the Port line: /Port
# 2. Change Port 22 to Port 2222
#    Move to "22" → ciw (change inner word) → type 2222 → Esc

# 3. Find PermitRootLogin: /PermitRootLogin
# 4. Change yes to no:
#    Move to "yes" → ciw → type no → Esc

# 5. Find PasswordAuthentication: /PasswordAuthentication
# 6. Make sure it says yes (for now) — same technique

# 7. Save and quit: :wq

# Verify the changes:
grep -E "Port|PermitRootLogin|PasswordAuthentication" ~/linux-course/part4/sshd_config
```

---

## 🧠 Deep Understanding — How Terminal Editors Work

### The TTY Connection

When you run `vim /etc/hosts`, here is what happens:

```
1. Terminal sends keypresses to Vim
2. Vim reads keypresses from stdin
3. Vim writes display updates to stdout
4. Terminal renders the output

This is why Vim CANNOT run in a background process
This is why Vim stops working if SSH disconnects
```

### Why Vim Exists in Two Versions

```bash
which vim
# /usr/bin/vim

which vi
# /usr/bin/vi
```

- **vi** — the original. On every Unix/Linux system. Minimal features.
- **vim** — improved version with syntax highlighting, visual mode, tabs.

Some minimal Docker containers or old Unix systems only have `vi`. Learn the basics of both.

### The Philosophy Behind Modal Editing

Normal mode is designed so that **common operations are one keystroke**:

```bash
# Without modal editing (Nano, VS Code):
# Delete a line:
#   1. Click at start of line
#   2. Hold Shift+Down (select)
#   3. Press Delete
#   = 3+ actions, 2 hands off home row

# With modal editing (Vim):
# dd
# = 2 keystrokes, fingers stay on home row
```

This is why Vim users claim they can edit faster. When you internalize the modes, your fingers never leave the keyboard home row.

### The Swap File Safety Net

Vim writes swap files to protect your work. This is critical when SSH disconnects:

```bash
# When you edit a file, Vim creates:
.swp   # Changes since last save (swap file)
.swo   # If .swp exists (second swap)
.swn   # Third level

# On clean exit, these are deleted.
# On crash, they remain for recovery.
# Always delete them after recovery: rm .*.sw?
```

---

## 📋 Summary — Complete Command Reference for Part 4

### Level 1: Basic — Getting Started with Terminal Editors

**Nano**
| Command | Action |
|---------|--------|
| `nano file` | Open file |
| `Ctrl+O` | Save |
| `Ctrl+X` | Exit |
| `Ctrl+W` | Search |
| `Ctrl+K` | Cut line |
| `Ctrl+U` | Paste |
| `Ctrl+_` | Go to line |
| `Alt+U` | Undo |

**Vim — Opening and Closing**
| Command | Action |
|---------|--------|
| `vim file` | Open file |
| `vim +25 file` | Open at line 25 |
| `:q` | Quit (fails if unsaved) |
| `:q!` | Force quit without saving |
| `:w` | Save |
| `:wq` | Save and quit |
| `:x` | Save and quit (same as :wq) |

**Vim — Modes**
| Key | Mode |
|-----|------|
| `i` | Insert mode (type text) |
| `v` | Visual mode (select text) |
| `V` | Visual line mode |
| `Ctrl+v` | Visual block mode |
| `Esc` | Return to Normal mode |
| `:` | Command mode |

### Level 2: Intermediary — Efficient Editing

**Vim — Navigation**
| Key | Action |
|-----|--------|
| `h` | Left |
| `j` | Down |
| `k` | Up |
| `l` | Right |
| `w` | Next word |
| `b` | Previous word |
| `0` | Start of line |
| `$` | End of line |
| `gg` | Start of file |
| `G` | End of file |
| `:50` | Go to line 50 |
| `Ctrl+f` | Page down |
| `Ctrl+b` | Page up |

**Vim — Editing**
| Key | Action |
|-----|--------|
| `x` | Delete character |
| `dd` | Delete (cut) line |
| `dw` | Delete word |
| `yy` | Copy (yank) line |
| `yw` | Copy word |
| `p` | Paste below |
| `P` | Paste above |
| `u` | Undo |
| `Ctrl+r` | Redo |
| `.` | Repeat last command |

**Vim — Search and Replace**
| Command | Action |
|---------|--------|
| `/term` | Search forward |
| `?term` | Search backward |
| `n` | Next match |
| `N` | Previous match |
| `:s/old/new` | Replace first on line |
| `:s/old/new/g` | Replace all on line |
| `:%s/old/new/g` | Replace all in file |
| `:%s/old/new/gc` | Replace all with confirm |

### Level 3: Advanced — Professional Editor Workflows

**Vim — Multi-file & Windows**
| Command | Action |
|---------|--------|
| `:next` | Next file |
| `:previous` | Previous file |
| `:files` | List buffers |
| `:split file` | Horizontal split |
| `:vsplit file` | Vertical split |
| `Ctrl+w j` | Down to next split |
| `Ctrl+w k` | Up to previous split |
| `vim -d f1 f2` | Diff two files |
| `]c` | Next diff |
| `[c` | Previous diff |
| `:!command` | Run shell command from Vim |
| `:r !command` | Insert command output into file |

---

## 🚀 What's Coming in Part 5

**Part 5: Pipes, Redirection, and Streams — The Power of Unix**

You will learn:
- How Linux handles input and output (stdin, stdout, stderr)
- Redirecting output to files, devices, and other programs
- Pipes — chaining commands together
- `tee` — splitting output to both screen and file
- Named pipes (FIFOs) — inter-process communication
- 15 hands-on practices

---

## 📝 Self-Test — Can You Answer These?

1. What is the difference between Vim's Normal mode and Insert mode?
2. How do you save and quit in Vim with a single command?
3. What does `dd` do in Vim? What does `yy` do?
4. How do you search for "error" in a file in Vim, then go to the next match?
5. What does `:%s/old/new/g` do?
6. How do you open two files side by side in Vim?
7. What is the difference between `vi` and `vim`?
8. How do you undo a change in Vim?
9. What does Nano's `Ctrl+O` do? `Ctrl+X`?
10. When would you choose Nano over Vim?
11. What is the swap file Vim creates and when would you use it?
12. How do you run a shell command from inside Vim?
13. What does `Ctrl+v` followed by `I` do in Vim?
14. What is the `~/.vimrc` file used for?
15. How do you compare two files in Vim?

**Score:** 12/15 correct = ready for Part 5.

---

*Linux SysAdmin Course | Part 4 of ∞ | Reverse Engineering Approach*
*Previous → Part 3: Users, Groups, and Permissions*
*Next → Part 5: Pipes, Redirection, and Streams*

[← Previous](part3.md) | [Next →](part5.md)
