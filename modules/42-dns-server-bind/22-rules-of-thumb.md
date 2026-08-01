## 📏 Rules of Thumb

### The DNS Server Rules

| Rule | Description | Why |
|------|-------------|-----|
| **Always test config** | `named-checkconf` | Prevent restart failures |
| **Increment serial** | On every zone change | Replication |
| **Use multiple NS** | Redundancy | Availability |
| **Monitor with logs** | `querylog on` | Debugging |

---

**Why these rules matters:** Following these rules ensures reliable DNS service.

[← Previous](21-self-test-15-questions.md) | [↑ Index](index.md)
