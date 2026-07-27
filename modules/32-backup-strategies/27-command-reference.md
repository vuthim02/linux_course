## 📋 Command Reference

### Level 1 Commands: tar, rsync, dd

**tar**
| Command | Description |
|---------|-------------|
| `tar cf a.tar /p/` | Create archive |
| `tar czf a.tar.gz /p/` | Create gzip archive |
| `tar xf a.tar` | Extract |
| `tar tf a.tar` | List |

**rsync**
| Command | Description |
|---------|-------------|
| `rsync -av /s/ /d/` | Local sync |
| `rsync -avz /s/ u@h:/d/` | Remote push |
| `rsync -avz u@h:/s/ /d/` | Remote pull |
| `rsync -av --delete /s/ /d/` | Mirror |
| `rsync -avn /s/ /d/` | Dry run |

**dd**
| Command | Description |
|---------|-------------|
| `dd if=/dev/sda of=i.img bs=4M status=progress` | Clone disk |
| `dd if=i.img of=/dev/sda bs=4M` | Restore image |
| `dd if=/dev/sda bs=4M conv=sync,noerror` | Skip errors |
| `dd if=/dev/zero of=s.img bs=1M seek=1000 count=0` | Sparse file |

### Level 2 Commands: tar Advanced, rsync Advanced, ddrescue, dump, Database

**tar**
| Command | Description |
|---------|-------------|
| `tar czf - /p/ \| ssh h "cat > b.tgz"` | Archive over SSH |
| `tar czf b.tgz --exclude='*.log' /p/` | Exclude |
| `tar --listed-incremental=s -czf i.tgz /p/` | Incremental |

**rsync**
| Command | Description |
|---------|-------------|
| `rsync -av --link-dest=D /s/ /d/` | Incremental hard-link |
| `rsync -av --bwlimit=1024 /s/ u@h:/d/` | Bandwidth limit |
| `rsync -aH /s/ /d/` | Preserve hard links |

**ddrescue**
| Command | Description |
|---------|-------------|
| `ddrescue -d /dev/sda img.dd map.log` | Recover failing disk |
| `ddrescue -d -r3 /dev/sda img.dd map.log` | Retry bad 3× |
| `ddrescuelog --list-bad map.log` | Show bad sectors |

**dump/restore**
| Command | Description |
|---------|-------------|
| `dump -0uf b.dump /dev/sda1` | Level 0 dump |
| `dump -1uf b.dump /dev/sda1` | Level 1 incremental |
| `restore -rf b.dump` | Full restore |
| `restore -if b.dump` | Interactive restore |

**Database**
| Command | Description |
|---------|-------------|
| `mysqldump --all-databases --single-transaction > b.sql` | MySQL dump |
| `pg_dump -Fc db > db.dump` | PostgreSQL dump |
| `pg_restore -d db db.dump` | PostgreSQL restore |
| `sqlite3 db ".backup b.db"` | SQLite backup |
| `mongodump --out /b/` | MongoDB dump |

### Level 3 Commands: Borg, Restic, Cloud

**Borg**
| Command | Description |
|---------|-------------|
| `borg init --encryption=repokey /r` | Init repo |
| `borg create --compression zstd,9 /r::a /p` | Create backup |
| `borg list /r` | List archives |
| `borg extract /r::a` | Extract |
| `borg mount /r::a /mnt` | Mount |
| `borg prune --keep-daily 7 /r` | Prune |
| `borg check --verify-data /r` | Integrity check |
| `borg info /r` | Dedup stats |

**Restic**
| Command | Description |
|---------|-------------|
| `restic init --repo /r` | Init repo |
| `restic backup /p` | Backup |
| `restic snapshots` | List snapshots |
| `restic restore latest --target /r` | Restore |
| `restic mount /mnt` | Mount FUSE |
| `restic forget --keep-daily 7 --prune` | Retention |
| `restic check --read-data` | Integrity check |
| `restic unlock` | Remove stale locks |

**Cloud**
| Command | Description |
|---------|-------------|
| `rclone sync /src/ remote:/dst/` | Sync to cloud |
| `rclone ls remote:/path/` | List cloud |
| `aws s3 sync /src/ s3://bucket/` | AWS S3 sync |

---



---

[← Previous](26-15-hands-on-practices.md) | [↑ Index](index.md) | [Next →](28-whats-coming-in-part-33.md)
