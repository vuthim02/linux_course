## 🔍 Section 13: Other Terminal Editors Worth Knowing

| Editor | Description |
|--------|-------------|
| **vi** | Original Vim. On every Unix system. No syntax highlighting. Learn it in case Vim isn't available. |
| **emacs** | The other major editor. Extremely powerful but heavy learning curve. |
| **neovim** | Modern Vim fork. Better plugin system, built-in terminal. |
| **micro** | Modern Nano-like editor with mouse support and syntax highlighting. |
| **ed** | The original line editor. One line at a time. Useful in scripts. |

```bash
# Using ed (surprisingly useful in scripts):
echo -e "a\nHello, World\n.\nw\nq" | ed file.txt
# This appends "Hello, World" to file.txt
```

### Key Takeaways
- `vi` (not Vim) exists on every Unix system — learn it as a fallback
- `neovim` is the modern choice if you want a Vim fork with better plugins
- `micro` is great for newcomers who want mouse support and modern keybindings
- `ed` is niche but invaluable in scripts where you need a non-interactive editor





[← Previous](16-section-12-nano-vs-vim.md) | [↑ Index](index.md) | [Next →](18-practice-section-15-hands-on-exercises.md)
