## 🔍 Section 3: Compression Tools Compared

| Tool | Extension | Speed | Compression Ratio | Use Case |
|------|-----------|-------|-------------------|----------|
| `gzip` | `.gz` | Fast | Medium | Daily use, log rotation |
| `bzip2` | `.bz2` | Medium | Better than gzip | Distribution packages |
| `xz` | `.xz` | Slow | Best | Long-term archiving |

### Standalone Compression Commands

```bash
# gzip
gzip file.txt              # Creates file.txt.gz, removes original
gzip -k file.txt           # Keep original file (gzip 1.6+)
gzip -d file.txt.gz        # Decompress (same as gunzip)
gunzip file.txt.gz         # Same as gzip -d
gzip -l file.txt.gz        # List compression info

# bzip2
bzip2 file.txt             # Creates file.txt.bz2
bzip2 -d file.txt.bz2      # Decompress
bunzip2 file.txt.bz2       # Same as bzip2 -d

# xz
xz file.txt                # Creates file.txt.xz
xz -d file.txt.xz          # Decompress
unxz file.txt.xz           # Same as xz -d
xz -l file.txt.xz          # List compression info
```

### Compression Levels

```bash
# All three tools support levels 1-9
# 1 = fastest, least compression
# 6 = default (good balance)
# 9 = slowest, best compression

gzip -1 file.txt    # Fast, less compression
gzip -9 file.txt    # Slow, best compression
xz -9 file.txt      # Very slow, very small
```

### Benchmark (Approximate)

| Tool | Compress Time | Size | Decompress Time |
|------|--------------|------|-----------------|
| None | 0s | 100 MB | 0s |
| gzip -1 | 2s | 35 MB | 0.5s |
| gzip -6 | 5s | 33 MB | 0.5s |
| gzip -9 | 10s | 32 MB | 0.5s |
| bzip2 -9 | 30s | 28 MB | 5s |
| xz -6 | 60s | 25 MB | 8s |
| xz -9 | 180s | 24 MB | 10s |

> 💡 **Default choice:** Use `gzip` (via `tar -czf`) for 99% of your work. It is fast enough and compresses well. Only use `xz` for long-term archives where size matters more than time.

---



---

[← Previous](03-section-2-tar-the-tape.md) | [↑ Index](index.md) | [Next →](05-section-4-viewing-and-manipulating.md)
