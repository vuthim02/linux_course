## Restore Testing
- Daily: Checksum verification after backup
- Weekly: Full restore to test environment
- Quarterly: Full DR drill (bare-metal)
```

### DR Response Flow

```
1. DETECT disaster (crash, corruption, ransomware, fire)
2. ASSESS damage (scope, can primary be recovered? RTO clock starts)
3. DECIDE strategy (same hardware, spare, cloud DR site)
4. RECOVER (OS → config → data → databases → test service)
5. VALIDATE (data correct? service responding? users connected?)
6. POST-MORTEM (actual RPO/RTO? root cause? update plan)
```

### Ransomware-Specific Strategy

```bash
# Immutable backups:
#   - S3 Object Lock
#   - Append-only Borg repos
#   - WORM tapes

# Air-gapped:
#   - Physically disconnected drives
#   - Separate backup VLAN with no inbound connections

# Versioned:
#   - Never overwrite old backups
#   - Borg/Restic naturally version everything

# Test ransomware recovery quarterly:
#   - Simulate: "all files encrypted, restore from backup"
```





[← Previous](23-storage.md) | [↑ Index](index.md) | [Next →](25-deep-understanding.md)
