## 🔍 Section 6: Update Strategies for Production

### Staged Rollout

```
Development Server
    ↓ (test updates)
Staging Server
    ↓ (validate with real workloads)
Production Server 1 (canary)
    ↓ (monitor for 24h)
Production Server 2-10
    ↓ (monitor for 48h)
All remaining servers
```

### Maintenance Windows

```bash
# Standard practice:
# - Schedule updates during low-traffic periods
# - 2 AM Sunday is common
# - Communicate with stakeholders
# - Have a rollback plan BEFORE starting

# For critical infrastructure:
# - Blue/green deployment (switch traffic to updated server)
# - Canary deployment (5% traffic to updated server)
# - Full deployment after validation
```

### Pre-Update Checklist

```bash
# 1. Check what will be updated
apt list --upgradable > pre-update-inventory.txt

# 2. Check if reboot is needed (kernel update)
# Check if kernel will be updated
apt list --upgradable 2>/dev/null | grep "^linux-image"

# 3. Check disk space
df -h

# 4. Take a snapshot (VM) or backup critical data

# 5. Have a rollback plan
```

### Post-Update Checklist

```bash
# 1. Verify services are running
systemctl --failed

# 2. Check for errors in logs
journalctl -p err --since "10 minutes ago"

# 3. Run critical application tests

# 4. If rebooted, verify system comes up clean
systemd-analyze
systemctl --failed

# 5. Document what was updated and why
```





[← Previous](08-section-4-unattended-upgrades.md) | [↑ Index](index.md) | [Next →](10-section-7-kernel-updates.md)
