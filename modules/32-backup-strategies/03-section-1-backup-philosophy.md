## 🔍 Section 1: Backup Philosophy

### The 3-2-1 Rule

```
3 copies of your data
2 different storage media
1 copy offsite
```

**3 copies:** Live data + 2 backups. If any one copy is lost, you still have another.
**2 different media:** Different failure modes — a disk controller failure won't wipe your tape.
**1 copy offsite:** Building burns, offsite survives — cloud, colo, friend's Raspberry Pi.

### RPO and RTO

| Term | Definition | Example |
|------|------------|---------|
| RPO | Recovery Point Objective — max acceptable data loss | 1 hour → can lose ≤ 1 hour |
| RTO | Recovery Time Objective — max acceptable downtime | 4 hours — must be back in 4 hours |

```
RPO ← determines backup frequency
RTO ← determines restore speed requirements
```

### Full, Incremental, Differential

```
Full:       [████████████████████████████████]
Incremental: [██][██][██] each captures changes since PRIOR backup (any type)
Differential: [██][████][██████] each captures changes since LAST FULL only

Restore: full + inc1 + inc2 + inc3 (replay all)
Restore: full + latest diff only (simpler chain)
```

| Type | Backup Speed | Restore Speed | Storage | Complexity |
|------|-------------|---------------|---------|------------|
| Full | Slowest | Fastest | Most | Simplest |
| Incremental | Fastest | Slowest (all must be intact) | Least | Most chain-dependent |
| Differential | Medium | Medium (full + 1) | Medium | Simpler than inc |

### Hot vs Cold

| Type | Description | Example |
|------|-------------|---------|
| Hot | Running, data changing | `mysqldump` while MySQL live (with locks) |
| Warm | Quiesced, not stopped | LVM snapshot, XFS freeze |
| Cold | Fully stopped | Shut down VM, copy disk image |

### What to Back Up

| Priority | What | Why |
|----------|------|-----|
| Critical | Databases, app data, user homes | The actual business data |
| Important | `/etc`, `/usr/local/etc` | Rebuild without configs is slow |
| Helpful | Package lists | `dpkg --get-selections` or `rpm -qa` |
| Exclude | `/proc`, `/sys`, `/dev`, `/run`, `/tmp` | Pseudo-filesystems, regenerated at boot |

### Key Insight

A backup that cannot be restored is not a backup. The most important metric is RTO measured during actual restore testing — not estimates.





[← Previous](02-level-1-basic-backup-philosophy.md) | [↑ Index](index.md) | [Next →](04-section-2-tar-tape-archiver.md)
