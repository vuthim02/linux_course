## 📏 Rules of Thumb

### The Namespace Rules

| Rule | Description | Why |
|------|-------------|-----|
| **Use nsenter** | Enter containers for debugging | Access |
| **Check /proc/PID/ns/** | Inspect namespace membership | Visibility |
| **Limit namespace scope** | Fewer namespaces = less overhead | Performance |
| **Combine with cgroups** | Isolation + resource limits | Security |

---

**Why these rules matters:** Following these rules ensures effective container isolation.

[← Previous](15-self-test.md) | [↑ Index](index.md)
