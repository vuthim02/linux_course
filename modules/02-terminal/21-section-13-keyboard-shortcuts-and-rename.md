## 🔍 Section 13: Readline Shortcuts and Batch Rename

### Bash Readline Keyboard Shortcuts

```bash
# Cursor movement
Ctrl+A    # Jump to beginning of line
Ctrl+E    # Jump to end of line
Alt+F     # Forward one word
Alt+B     # Back one word

# Editing
Ctrl+U    # Cut from cursor to beginning
Ctrl+K    # Cut from cursor to end
Ctrl+W    # Cut previous word
Ctrl+Y    # Paste (yank) last cut text
Ctrl+T    # Swap last two characters
Alt+T     # Swap last two words

# History
Ctrl+R    # Search command history (reverse-i-search)
Ctrl+P    # Previous command (like up arrow)
Ctrl+N    # Next command (like down arrow)
!!        # Repeat last command
!$        # Last argument of previous command
!$:p      # Print last argument (don't execute)
```

### rename — Batch File Renaming

```bash
# Rename files using a Perl expression
rename 's/\.JPG$/\.jpg/' *     # Lowercase extensions
rename 's/ /_/g' *             # Replace spaces with underscores
rename 'y/A-Z/a-z/' *          # Lowercase all names
rename 's/^/backup_/' *        # Prefix all files
rename 's/IMG_(\d{4})/photo_$1/' *  # Use captured groups
```

### shopt — Shell Option Management

```bash
shopt -s extglob               # Enable extended globs
# Extended glob patterns:
# ?(pattern)   — match zero or one
# *(pattern)   — match zero or more
# +(pattern)   — match one or more
# @(pattern)   — match exactly one
# !(pattern)   — match anything except

# Examples with extglob:
ls !(*.txt)                    # All files NOT ending in .txt
ls file+([0-9]).txt            # file1.txt, file99.txt

shopt -s dotglob               # Include hidden files in globs
shopt -s globstar              # ** matches recursive directories
ls **/*.conf                   # All .conf files in all subdirs
```



[← Previous](20-section-12-file-stat-and-advanced-metadata.md) | [↑ Index](index.md) | [Next →](../03-users-groups-permissions/01-what-you-will-achieve-in.md)
