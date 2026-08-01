## 📏 Rules of Thumb

### The Monitoring Rules

| Rule | Description | Why |
|------|-------------|-----|
| **Alert on symptoms** | Not causes | Actionable |
| **Use rate() for alerts** | Smoothed average | Reliable |
| **Use irate() for graphs** | Instantaneous spikes | Visual |
| **Set recording rules** | Pre-compute expensive queries | Performance |
| **Use labels wisely** | High cardinality kills | Efficiency |

---

**Why these rules matters:** Following these rules ensures effective monitoring without noise.

[← Previous](21-self-test.md) | [↑ Index](index.md)
