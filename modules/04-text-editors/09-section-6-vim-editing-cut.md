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





[← Previous](08-section-5-vim-navigation-moving.md) | [↑ Index](index.md) | [Next →](10-section-7-vim-search-and.md)
