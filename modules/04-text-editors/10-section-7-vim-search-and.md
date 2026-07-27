## 🔍 Section 7: Vim Search and Replace

### Searching

```bash
/error       # Search forward for "error"
?error       # Search backward for "error"
n            # Next match
N            # Previous match

# Case-insensitive search
/error\c     # \c makes search case-insensitive

# Highlight all matches
:set hlsearch
# :nohlsearch  to remove highlights temporarily
```

### Search and Replace

```bash
# Replace first match on current line
:s/old/new

# Replace all matches on current line
:s/old/new/g

# Replace all matches in entire file
:%s/old/new/g

# Replace with confirmation (ask each time)
:%s/old/new/gc

# Replace only in lines 10-20
:10,20s/old/new/g

# Replace using regex (wildcards)
:%s/foo.*bar/new/g
```

### The Most Common SysAdmin Find-and-Replace

```bash
# Change a port number in a config file
:%s/Port 22/Port 2222/g

# Replace all IP addresses
:%s/192.168.1.100/192.168.2.100/g

# Add a prefix to every line
:%s/^/PREFIX/

# Add a suffix to every line
:%s/$/SUFFIX/
```

---



---

[← Previous](09-section-6-vim-editing-cut.md) | [↑ Index](index.md) | [Next →](11-section-8-vim-visual-mode.md)
