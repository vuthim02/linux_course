## 🔍 Section 3: rsync — Remote Sync (Basic)

### Basic Syntax

```bash
rsync [options] SOURCE DESTINATION
rsync [options] SOURCE user@host:DESTINATION    # Push
rsync [options] user@host:SOURCE DESTINATION    # Pull
```

### Key Options

| Option | Description |
|--------|-------------|
| `-a` | Archive: recursive + preserve all metadata (-rlptgoD) |
| `-v` | Verbose |
| `-z` | Compress during transfer |
| `-n` | Dry run |
| `--delete` | Delete files in dest not in source |
| `--bwlimit` | Bandwidth limit in KB/s |
| `--exclude` | Exclude pattern |
| `-H` | Preserve hard links |

### Local & Remote

```bash
# Local
rsync -av /source/directory/ /destination/directory/
# Trailing slash: copies CONTENTS of dir; no slash: copies dir itself

# Remote over SSH
rsync -avz /home/user/data/ user@backup-server:/backups/data/
rsync -avz -e 'ssh -p 2222' /data/ user@host:/backups/

# Remote daemon
rsync -av rsync://backup@backup-server/backups/ /local/restore/
```

### Bandwidth Limiting

```bash
rsync -avz --bwlimit=1024 /data/ user@host:/backups/   # 1 MB/s max
```

---



---

[← Previous](04-section-2-tar-tape-archiver.md) | [↑ Index](index.md) | [Next →](06-section-4-dd-and-ddrescue.md)
