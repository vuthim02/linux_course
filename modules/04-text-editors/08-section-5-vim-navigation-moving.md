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



---

[← Previous](07-level-2-intermediary-efficient-editing.md) | [↑ Index](index.md) | [Next →](09-section-6-vim-editing-cut.md)
