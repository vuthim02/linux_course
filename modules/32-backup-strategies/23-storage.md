## Storage

Backup storage must follow the 3-2-1 rule: three copies, two media types, one offsite. The storage strategy below implements this for a production environment.

### Storage Tiers

| Tier | Medium | Retention | Purpose |
|------|--------|-----------|---------|
| **Primary** | Local NAS (RAID 6) | 30 days | Fast recovery — accidental deletion, file restore |
| **Secondary** | Offsite cloud (S3 + Glacier) | 12 months | Disaster recovery — fire, flood, ransomware |

### Why RAID 6 for NAS
RAID 6 tolerates two simultaneous drive failures — critical for backup storage that must survive hardware issues while you're restoring data.

### Cloud Storage Options

| Provider | Storage Class | Retrieval Cost | Best For |
|----------|--------------|----------------|----------|
| AWS S3 Standard | High | Low | Recent backups (30 days) |
| AWS S3 Glacier | Low | High | Long-term archives |
| Backblaze B2 | Low | Low | Budget-friendly offsite |
| Wasabi | Low | None | No egress fees |

### Choosing Your Storage
- **NAS**: Best for fast local restores (minutes, not hours)
- **Cloud**: Best for geographic redundancy and ransomware protection
- **Tape**: Best for very long-term archival (7+ years, regulatory compliance)


[← Previous](22-retention.md) | [↑ Index](index.md) | [Next →](24-restore-testing.md)
