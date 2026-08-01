## 🔍 Section 2: Debian/Ubuntu Repositories — sources.list

### The sources.list File

```bash
cat /etc/apt/sources.list
```

```
deb http://archive.ubuntu.com/ubuntu jammy main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu jammy-security main restricted
deb http://archive.ubuntu.com/ubuntu jammy-updates main restricted universe multiverse
```

### Anatomy of a Repository Line

```
deb  http://archive.ubuntu.com/ubuntu  jammy         main restricted
│    │                                  │             │
│    │                                  │             └── Components
│    │                                  └── Suite/Codename
│    └── Repository URL
└── Type (deb = binary, deb-src = source)
```

### Repository Types

| Type | Contents |
|------|----------|
| `deb` | Binary packages (.deb) |
| `deb-src` | Source packages (.dsc, .tar.gz) |

### Distribution Suites

```bash
# For Ubuntu:
# jammy (22.04) — Codename for a release
# jammy-security — Security updates
# jammy-updates — Bug fixes and updates
# jammy-backports — Backported software from newer releases
# jammy-proposed — Pre-release testing (use with caution)

# For Debian:
# stable — Current stable release
# testing — Next release (rolling)
# unstable (sid) — Development, always rolling
# stable-updates — Updates for stable
# stable-security — Security updates
```

### Components

```bash
# Ubuntu:
# main        — Canonical-supported free software
# universe    — Community-maintained free software
# restricted  — Proprietary drivers (supported)
# multiverse  — Non-free, legally restricted

# Debian:
# main        — DFSG-free software
# contrib     — Free software that depends on non-free
# non-free    — Non-free software
# non-free-firmware — Non-free firmware (Debian 12+)
```

### Sources List Options

APT supports additional options in brackets after the type:

```
deb [arch=amd64 signed-by=/etc/apt/keyrings/repo.asc] http://example.com jammy main
    │                                  │
    │                                  └── signed-by: Scopes GPG key to this repo
    └── arch: Only use for specific architectures
```

| Option | Purpose | Example |
|--------|---------|---------|
| `arch=` | Limit to specific architecture | `arch=amd64` or `arch=i386` |
| `signed-by=` | Scoped GPG key for verification | `signed-by=/etc/apt/keyrings/docker.asc` |
| `trusted=yes` | Skip GPG verification (not recommended) | `trusted=yes` |
| `check-valid-until=no` | Ignore expired Release file | `check-valid-until=no` |
| `allow-insecure=yes` | Allow unsigned repos (dangerous) | `allow-insecure=yes` |

### DEB822 Format (.sources files)

Modern Debian/Ubuntu support a new key-value format (DEB822) in `/etc/apt/sources.list.d/`:

```
# /etc/apt/sources.list.d/example.sources
Types: deb
URIs: http://example.com/ubuntu
Suites: jammy
Components: main universe
Architectures: amd64
Signed-By: /etc/apt/keyrings/example.asc
```

Advantages over one-line format:
- More readable (key-value pairs)
- Multiple URIs per entry
- Multiple suites per entry
- Better for automation

```bash
# Both formats work — .list (old) and .sources (new)
ls /etc/apt/sources.list.d/
# docker.list        → Old one-line format
# docker.sources     → New DEB822 format
```

### The sources.list.d Directory

Modern systems use separate files in `/etc/apt/sources.list.d/`:

```bash
# View repository files
ls /etc/apt/sources.list.d/

# Each file follows the same syntax as sources.list
cat /etc/apt/sources.list.d/docker.list
```





[← Previous](03-section-1-repository-architecture.md) | [↑ Index](index.md) | [Next →](05-level-2-intermediary-ppas-rpm.md)
