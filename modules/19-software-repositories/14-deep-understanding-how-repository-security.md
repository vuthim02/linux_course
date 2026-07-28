## 🧠 Deep Understanding — How Repository Security Works

### The Chain of Trust

```
YOU (trust)
    ↓
Repository GPG key (trust the key)
    ↓
Repository Release file (signed by the GPG key)
    ↓
Packages.gz checksum (verified against Release file)
    ↓
.deb / .rpm packages (verified against Packages.gz checksum)
    ↓
Package signature (optional, maintained by packager)
```

### GPG Key Types

```bash
# Two types of signatures:
# 1. Release file signature — ensures metadata is authentic
# 2. Package signature — ensures individual .deb is authentic

# APT verifies the Release file signature
# The Release file contains checksums of Packages.gz
# Packages.gz contains checksums of individual .deb files
# So verifying Release → verifies everything

# Repository signing with signed-by (modern):
# The key is scoped to ONLY the repository that references it
# Even if the key is compromised, only that repo is affected
```

### Mirror Selection

```bash
# How APT selects a mirror:
# 1. Reads the base URL from sources.list
# 2. If mirror:// is used, queries a mirror database
# 3. Tests latency to available mirrors
# 4. Picks the fastest one

# How DNF selects a mirror:
# 1. Reads metalink= URL
# 2. Metalink returns a list of mirrors + checksums
# 3. DNF picks one and verifies the content
```





[← Previous](13-practice-section-15-hands-on-exercises.md) | [↑ Index](index.md) | [Next →](15-summary-command-reference-for-part.md)
