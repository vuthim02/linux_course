## Retention

Retention policies define how long backups are kept. Too short — you can't recover old data. Too long — you waste storage. The right policy balances protection against cost.

### Recommended Retention Schedule

| Backup Age | Retention | Purpose |
|------------|-----------|---------|
| **Daily** | 30 days | Recent recovery — accidental deletion, corruption |
| **Weekly** | 12 weeks (~3 months) | Medium-term — catching mistakes discovered late |
| **Monthly** | 12 months (~1 year) | Long-term — compliance, audit trails |
| **Yearly** | 7 years (if regulated) | Legal/regulatory requirements (finance, healthcare) |

### Implementing with Borg

```bash
# Keep 7 daily, 4 weekly, 6 monthly, 2 yearly
borg prune --keep-daily=7 --keep-weekly=4 --keep-monthly=6 --keep-yearly=2 /backup/borg-repo
```

### Implementing with Restic

```bash
# Keep 7 daily, 4 weekly, 6 monthly
restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --prune /backup/restic-repo
```

### Key Principles
- Always prune AFTER a successful backup, not before
- Test restores at each retention tier — a backup you can't restore is worthless
- Regulatory requirements override convenience — know your compliance obligations


[← Previous](21-schedule.md) | [↑ Index](index.md) | [Next →](23-storage.md)
