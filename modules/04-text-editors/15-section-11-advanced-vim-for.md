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



---

[← Previous](14-level-3-advanced-professional-editor.md) | [↑ Index](index.md) | [Next →](16-section-12-nano-vs-vim.md)
