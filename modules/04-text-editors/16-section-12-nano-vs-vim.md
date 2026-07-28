## 🔍 Section 12: Nano vs Vim — When to Use Which

| Scenario | Editor |
|----------|--------|
| Change one line in a config file over SSH | **Nano** (faster to open/save) |
| Write a 100-line bash script | **Vim** (syntax highlighting, modal editing) |
| Emergency fix during an outage | **Nano** (less cognitive load under pressure) |
| Heavy text processing (column edits) | **Vim** (visual block mode is unique) |
| Editing a file you've never seen before | **Nano** (read the file, make quick change) |
| Writing code daily | **Vim** (learn it, invest the time) |
| Server with minimal tools installed | **Nano** (always available, vi is sometimes aliased) |

### Quick Decision Rule
> Use **Nano** for anything under 20 lines or when you're under pressure.
> Use **Vim** for anything you'll edit more than once or that requires search/replace.

### Key Takeaways
- Nano is the safe choice when you just need to get in, edit, and get out
- Vim rewards investment — the more you use it, the faster you become
- Emergency edits during outages: reach for Nano (lower cognitive load)
- Daily scripting and config work: invest in Vim muscle memory





[← Previous](15-section-11-advanced-vim-for.md) | [↑ Index](index.md) | [Next →](17-section-13-other-terminal-editors.md)
