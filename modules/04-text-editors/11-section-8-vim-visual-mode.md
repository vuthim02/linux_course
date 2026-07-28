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





[← Previous](10-section-7-vim-search-and.md) | [↑ Index](index.md) | [Next →](12-section-9-vim-configuration-vimrc.md)
