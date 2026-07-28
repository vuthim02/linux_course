## 🔍 Section 1: Repository Architecture

### What Is a Repository?

A repository is a server (or directory) containing:
- **Packages** — .deb or .rpm files
- **Metadata** — index of what packages, versions, and dependencies are available
- **Release files** — signed checksums of the metadata
- **GPG keys** — for verifying authenticity

### The Repository Workflow

```
1. Repository maintainer builds packages
2. Creates metadata (Packages.gz, Packages.xz)
3. Signs the Release file with GPG
4. Uploads everything to a server
5. You run: apt update
6. Your system downloads the metadata
7. Verifies the GPG signature
8. Now apt knows what's available
9. You run: apt install nginx
10. apt downloads, verifies, and installs
```

### Repository Structure

```
Debian repository layout:
http://archive.ubuntu.com/ubuntu/
    ├── dists/
    │   └── jammy/                    ← Distribution codename
    │       ├── Release              ← Signed metadata index
    │       ├── Release.gpg          ← GPG signature
    │       ├── main/
    │       │   ├── binary-amd64/
    │       │   │   ├── Packages.gz  ← Package index (compressed)
    │       │   │   └── Packages.xz  ← Package index (more compressed)
    │       │   └── source/          ← Source packages
    │       ├── universe/
    │       ├── restricted/
    │       └── multiverse/
    └── pool/
        └── main/                    ← Actual .deb files
            └── n/
                └── nginx/
                    └── nginx_1.18.0-0ubuntu1_amd64.deb
```





[← Previous](02-level-1-basic-repository-architecture.md) | [↑ Index](index.md) | [Next →](04-section-2-debianubuntu-repositories-sourceslist.md)
