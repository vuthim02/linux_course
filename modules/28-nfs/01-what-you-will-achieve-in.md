## 🎯 What You Will Achieve in Part 28

| Level | Focus | Skills Gained |
|-------|-------|--------------|
| **⭐ Level 1: Basic** | NFS Concepts & Installation | Understand RPC, XDR, protocol versions; install and verify NFS server |
| **⭐ Level 2: Intermediary** | Server/Client Configuration | Set up exports, mount shares, configure autofs, apply security (root_squash, Kerberos), troubleshoot |
| **⭐ Level 3: Advanced** | Performance & Internals | Tune rsize/wsize/RDMA, benchmark with nfsstat, understand pNFS, locking delegation, and deep protocol mechanics |

### Why This Part Matters
NFS is the backbone of shared storage in Linux environments — from home directories served to hundreds of workstations to high-performance computing clusters accessing shared datasets. Understanding NFS at every level, from basic exports to protocol internals, is essential for managing shared filesystems at scale.

Complete **15 hands-on practices** across all levels.

> **Real-world relevance**: NFS is everywhere — from small offices sharing a printer to enterprise data centers running parallel computing workloads. A misconfigured export can expose sensitive data, and a slow NFS mount can bring an entire application cluster to its knees. These skills are directly applicable to production environments.

**Skills progression in this part**:
- **Basic**: Understand NFS protocol versions (v3, v4, v4.1), install and verify the NFS server, identify key daemons (`rpcbind`, `nfsd`, `mountd`)
- **Intermediary**: Configure `/etc/exports` with security options, set up autofs for on-demand mounting, integrate NFS with LVM, troubleshoot stale mounts and permission issues
- **Advanced**: Tune `rsize`/`wsize` for throughput, configure pNFS for parallel access, understand NFS locking delegation, compare NFS with SMB/CIFS and CephFS


[↑ Index](index.md) | [Next →](02-level-1-basic-nfs-fundamentals.md)
