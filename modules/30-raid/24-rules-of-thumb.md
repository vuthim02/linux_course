## 📏 Rules of Thumb

### The RAID Rules

| Rule | Description | Why |
|------|-------------|-----|
| **RAID is not backup** | Protects against disk failure | Data safety |
| **Use RAID 10 for databases** | Best write performance | Performance |
| **Use RAID 5/6 for archives** | Good capacity efficiency | Storage |
| **Monitor SMART** | Predict failures | Prevention |
| **Replace failed drives immediately** | Don't wait | Redundancy |

### The "Drive Failed" Checklist

```bash
# 1. Check status:
cat /proc/mdstat

# 2. Identify failed drive:
mdadm --detail /dev/md0

# 3. Mark as failed:
mdadm --manage /dev/md0 --fail /dev/sdb

# 4. Remove:
mdadm --manage /dev/md0 --remove /dev/sdb

# 5. Add replacement:
mdadm --manage /dev/md0 --add /dev/sdd

# 6. Monitor rebuild:
watch cat /proc/mdstat
```

---

**Why these rules matter:** Following these rules prevents data loss and ensures RAID arrays stay healthy.

[← Previous](21-self-test-can-you-answer-these.md) | [↑ Index](index.md)
