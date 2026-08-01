## 📏 Rules of Thumb

### The Kubernetes Rules

| Rule | Description | Why |
|------|-------------|-----|
| **Use declarative config** | YAML files | Reproducibility |
| **Set resource requests** | Ensure scheduling | Reliability |
| **Use health checks** | Liveness/readiness probes | Self-healing |
| **Check logs --previous** | For CrashLoopBackOff | Debugging |

---

**Why these rules matters:** Following these rules ensures reliable Kubernetes operations.

[← Previous](18-self-test.md) | [↑ Index](index.md)
