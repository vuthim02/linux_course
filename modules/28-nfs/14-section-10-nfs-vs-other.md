## 🔍 Section 10: NFS vs Other Network Filesystems

### Comparison Table

| Feature | NFSv4 | CIFS/SMB | GlusterFS | CephFS |
|---------|-------|----------|-----------|--------|
| **Protocol** | ONC RPC | SMB2/3 | Custom over TCP | CRUSH + librados |
| **Native to** | Linux/Unix | Windows | Linux | Linux |
| **POSIX compliance** | Full | Partial | Full | Mostly |
| **Locking** | Built-in (lease) | Oplocks/leases | POSIX locks | Distributed locks |
| **Kerberos** | Yes (sec=krb5) | Yes | No | No |
| **Encryption** | Kerberos/TLS | SMB3 encryption | SSL/TLS (TLS) | Encryption in-transit |
| **Parallel I/O** | pNFS (v4.1+) | SMB multi-channel | Yes (distributed) | Yes (distributed) |
| **Scalability** | Single server | Single server | Multi-server (distributed) | Multi-server (distributed) |
| **Clustering** | NFS-Ganesha + CTDB | Samba CTDB | Built-in | Built-in |
| **Snapshot** | No (filesystem dep.) | VSS (Windows) | Yes | Yes |
| **Ease of setup** | Easy | Moderate | Moderate | Complex |
| **Use case** | Linux-to-Linux file sharing | Windows interop | Scale-out NAS | Object + block + file |
| **Client in kernel?** | Yes | Yes | FUSE | FUSE (kclient experimental) |
| **License** | BSD (kernel) | GPL | GPLv2+ | LGPL |

### When to Use What

```bash
# NFS: Linux-to-Linux, simple shared storage, home directories
# CIFS/SMB: Windows clients, mixed environments, printers
# GlusterFS: Scale-out NAS, large media, high availability without SAN
# Ceph: Unified storage (block + object + file), cloud platforms, OpenStack

# Migration path: NFS → GlusterFS/Ceph for scaling
# Migration path: NFS → Samba for Windows clients
```

### Performance Comparison (Approximate)

```bash
# Single-stream throughput (1GbE):
#   NFSv4 sync:      ~112 MB/s
#   NFSv4 async:     ~112 MB/s (network-limited)
#   CIFS/SMB3:       ~110 MB/s
#   GlusterFS:       ~100-110 MB/s
#   CephFS (FUSE):   ~80-100 MB/s
#   CephFS (kclient): ~110 MB/s

# Metadata operations (creates/sec):
#   NFSv4:     ~5000
#   CIFS/SMB3: ~3000
#   GlusterFS: ~2000
#   CephFS:    ~1000-3000
```

---



---

[← Previous](13-section-9-troubleshooting.md) | [↑ Index](index.md) | [Next →](15-section-11-locking-in-nfs.md)
