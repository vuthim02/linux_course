## 🔍 Section 6: Modern Alternatives — rg, ag, ack

### ripgrep (rg) — The Fastest

```bash
# Install
sudo apt install ripgrep        # Debian/Ubuntu
sudo dnf install ripgrep         # Fedora
```

```bash
# Default search (recursive, respects .gitignore)
rg "pattern"

# Show line numbers
rg -n "pattern"

# Case-insensitive
rg -i "pattern"

# Show context
rg -C 5 "pattern"

# Search only .log files
rg -g "*.log" "error"

# Search but exclude a pattern
rg -g "*.log" "error" --glob '!access.log'
```

### Why ripgrep Is Better Than grep for Large Codebases

```bash
# ripgrep is 5-10x faster on large directories
# It automatically ignores:
#   - .gitignore patterns
#   - Hidden files (unless you use -.)
#   - Binary files
#   - Symlinks (unless -L)

# Compare:
time grep -r "pattern" /usr/src   # Slow
time rg "pattern" /usr/src        # Fast
```

### silver searcher (ag) and ack

```bash
# ag — similar to rg, very fast
ag "pattern"

# ack — Perl-compatible regex, developer-focused
ack "pattern"
```





[← Previous](06-section-5-locate-instant-filename.md) | [↑ Index](index.md) | [Next →](08-section-7-looking-at-files.md)
