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





[← Previous](12-section-9-vim-configuration-vimrc.md) | [↑ Index](index.md) | [Next →](14-level-3-advanced-professional-editor.md)
