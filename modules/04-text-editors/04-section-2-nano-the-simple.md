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



---

[← Previous](03-section-1-why-terminal-text.md) | [↑ Index](index.md) | [Next →](05-section-3-vim-the-professionals.md)
