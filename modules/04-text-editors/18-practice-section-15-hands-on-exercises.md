## 💻 PRACTICE SECTION — 15 Hands-On Exercises

### Level 1 Practices — Getting Started with Terminal Editors


### ✅ Practice 1: Create a Practice Directory

```bash
mkdir -p ~/linux-course/part4
cd ~/linux-course/part4
echo "This is a test file." > test.txt
echo "Line 2" >> test.txt
echo "Line 3" >> test.txt
```


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


### ✅ Practice 6: Vim Insert Mode Practice

```bash
vim ~/linux-course/part4/test.txt

# 1. Press i to enter insert mode
# 2. Type: "---START OF FILE---"
# 3. Press Enter
# 4. Press Esc to return to normal mode
# 5. Type :wq and press Enter
```


### Level 2 Practices — Efficient Editing


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


### Level 3 Practices — Professional Editor Workflows


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





[← Previous](17-section-13-other-terminal-editors.md) | [↑ Index](index.md) | [Next →](19-deep-understanding-how-terminal-editors.md)
