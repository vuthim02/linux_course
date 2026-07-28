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





[← Previous](04-section-2-nano-the-simple.md) | [↑ Index](index.md) | [Next →](06-section-4-vim-survival-guide.md)
