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
## Answer Key
### Q1: What is the difference between Vim's Normal mode and Insert mode?
**Answer:** Normal mode interprets keystrokes as commands (movement, editing). Insert mode allows typing text into the buffer. Press `i` to enter Insert mode, `Esc` to return to Normal mode.
### Q2: How do you save and quit in Vim with a single command?
**Answer:** `:wq` or `:x` or `ZZ` (in Normal mode).
### Q3: What does `dd` do? What does `yy` do?
**Answer:** `dd` deletes (cuts) the current line. `yy` yanks (copies) the current line. Paste with `p`.
### Q4: How do you search for "error" and go to the next match?
**Answer:** `/error` then press `Enter`. Press `n` for next match, `N` for previous.
### Q5: What does `:%s/old/new/g` do?
**Answer:** Substitutes all occurrences of "old" with "new" on every line in the file. Without `g`, it replaces only the first match per line.
### Q6: How do you open two files side by side?
**Answer:** `:vsp filename` (vertical split) or `:sp filename` (horizontal split). Use `Ctrl+w` then arrow keys to switch between splits.
### Q7: What is the difference between `vi` and `vim`?
**Answer:** `vim` (Vi IMproved) is an enhanced version of `vi` with features like syntax highlighting, multi-level undo, tab completion, and visual mode.
### Q8: How do you undo a change in Vim?
**Answer:** Press `u` in Normal mode for single undo. `Ctrl+r` to redo. `:earlier 5m` to go back 5 minutes.
### Q9: What does Nano's `Ctrl+O` do? `Ctrl+X`?
**Answer:** `Ctrl+O` saves (WriteOut) the file. `Ctrl+X` exits Nano (prompts to save if modified).
### Q10: When would you choose Nano over Vim?
**Answer:** For quick edits, especially for beginners or when you just need a simple, intuitive editor. Nano shows shortcut keys at the bottom.
### Q11: What is the swap file Vim creates and when would you use it?
**Answer:** Vim creates a `.swp` file for recovery after crashes. Use `vim -r filename` to recover from it.
### Q12: How do you run a shell command from inside Vim?
**Answer:** `:!command` (e.g., `:!ls`). Use `:shell` to get a full shell; type `exit` to return.
### Q13: What does `Ctrl+v` followed by `I` do in Vim?
**Answer:** Enters Visual Block mode, then `I` inserts text at the beginning of each selected line (column editing).
### Q14: What is the `~/.vimrc` file used for?
**Answer:** User configuration file for Vim — stores settings like `set number`, `syntax on`, key mappings, and plugin configs.
### Q15: How do you compare two files in Vim?
**Answer:** `vimdiff file1 file2` or open both in Vim and use `:diffthis` in each buffer.
*Linux SysAdmin Course | Part 4 of ∞ | Reverse Engineering Approach*
*Previous → Part 3: Users, Groups, and Permissions*
*Next → Part 5: Pipes, Redirection, and Streams*
[← Previous](21-whats-coming-in-part-5.md) | [↑ Index](index.md)
