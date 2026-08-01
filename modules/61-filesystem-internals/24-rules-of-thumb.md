## 📏 Rules of Thumb

### The Filesystem Rules

| Rule | Description | Why |
|------|-------------|-----|
| **Monitor inode usage** | Prevent file creation failures | Availability |
| **Use noatime** | Reduce unnecessary writes | Performance |
| **Choose right filesystem** | Match workload | Optimization |
| **Backup metadata** | Metadata is critical | Recovery |

---

**Why these rules matters:** Following these rules ensures reliable filesystem operations.

[← Previous](15-self-test.md) | [↑ Index](index.md)
