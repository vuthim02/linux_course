## 🚀 What's Coming in Part 28

**Part 28: Network File System (NFS)**

You will learn:
- NFS protocol versions (v3, v4, v4.1, v4.2) — what changed and why it matters
- Setting up an NFS server and client from scratch
- Exporting filesystems with `/etc/exports` — access rules and options
- NFS security — `root_squash`, `no_all_squash`, Kerberos authentication
- NFSv4 pseudo-filesystem and stateful operations
- Performance tuning with `rsize`/`wsize` and RDMA
- Autofs — automatic NFS mounting on demand (no stale mounts)
- Locking delegation and comparing NFS to CIFS, GlusterFS, and CephFS
- 15 hands-on practices

### How Part 27 Connects
NFS relies on the same name resolution you just mastered. When an NFS client mounts a share by hostname, it goes through the exact same resolution chain — `/etc/hosts`, nsswitch, systemd-resolved — that you learned to debug. Understanding DNS internals will help you troubleshoot NFS connectivity issues that many admins struggle with.


[← Previous](19-summary-complete-command-reference-for.md) | [↑ Index](index.md) | [Next →](21-self-test-can-you-answer-these.md)
