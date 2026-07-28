## 🔍 Section 5: LTS vs Rolling Release

### LTS (Long Term Support)

| Aspect | LTS |
|--------|-----|
| Release cycle | Every 2 years (Ubuntu), 3-4 years (Debian) |
| Support period | 5-10 years |
| Package versions | Frozen at release (with backports) |
| Stability | Very high |
| New features | Rarely (mostly security + bug fixes) |
| Upgrade | Major upgrade every 2+ years |

**Examples:** Ubuntu 22.04 LTS, Debian 12, RHEL 9, Rocky 9

### Rolling Release

| Aspect | Rolling |
|--------|---------|
| Release cycle | Continuous |
| Support period | Always current |
| Package versions | Always latest |
| Stability | Lower (bleeding edge) |
| New features | Constantly |
| Upgrade | Never (always up to date) |

**Examples:** Arch Linux, openSUSE Tumbleweed

### Which to Choose?

| Use Case | Recommendation |
|----------|---------------|
| Production servers | LTS |
| Desktop (stable) | LTS |
| Desktop (latest hardware) | Rolling |
| Development/Testing | Either |
| Embedded/IoT | LTS |
| Containers | LTS |

### The Hybrid Approach

```bash
# Use LTS base, but pull specific packages from backports
# Example: Install newer kernel on Ubuntu LTS
sudo apt install -t jammy-backports linux-image-6.2

# Or enable specific PPAs for newer versions of specific software
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt install python3.12
```





[← Previous](05-section-3-applying-updates.md) | [↑ Index](index.md) | [Next →](07-level-2-intermediary-automation-and.md)
