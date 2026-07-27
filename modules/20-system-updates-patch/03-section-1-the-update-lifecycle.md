## 🔍 Section 1: The Update Lifecycle

### Where Updates Come From

```
Upstream Developer (e.g., Nginx team)
    └── Releases new version 1.24.0
              │
              ▼
Distribution Packager (e.g., Debian/Ubuntu maintainer)
    └── Packages it for the distribution
        └── Tests with distribution libraries
        └── Applies distribution-specific patches
        └── Signs with distribution GPG key
              │
              ▼
Distribution Repository
    └── Released to -proposed (testing)
    └── Promoted to -updates (stable)
    └── Security fixes → -security (urgent)
              │
              ▼
Your System (apt update / apt upgrade)
```

### Update Channels

| Channel | Content | Urgency |
|---------|---------|---------|
| `-security` | Critical security fixes | Install ASAP |
| `-updates` | Bug fixes, non-security improvements | Install on schedule |
| `-backports` | Newer versions from later releases | Optional |
| `-proposed` | Pre-release testing | DO NOT use in production |

### Types of Updates

| Type | Example | Risk |
|------|---------|------|
| Security patch | Fix for CVE in OpenSSL | Low (minimal code change) |
| Bug fix | Fix crash in NFS driver | Low |
| Minor version | 1.2.3 → 1.2.4 | Low |
| Major version | 1.x → 2.x | HIGH (breaking changes) |
| Kernel update | 6.1 → 6.2 | Medium (requires reboot) |
| Library update | libssl 1.1 → 3.0 | HIGH (may break apps) |

---



---

[← Previous](02-level-1-basic-package-management.md) | [↑ Index](index.md) | [Next →](04-section-2-checking-for-updates.md)
