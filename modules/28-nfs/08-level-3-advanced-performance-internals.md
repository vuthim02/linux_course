## ⭐ Level 3: Advanced — Performance, Internals, and Protocol Deep Dive

![pNFS Architecture](https://upload.wikimedia.org/wikipedia/commons/thumb/5/5d/NFSv4.1_pNFS_Architecture.svg/220px-NFSv4.1_pNFS_Architecture.svg.png)  
*pNFS parallel data access — separating metadata from data. Image credit: Wikimedia Commons.*

> **Level 3 Goal:** Master NFS performance tuning with rsize/wsize, RDMA, and nfsstat benchmarking. Understand pNFS layout protocol, NFS locking delegation (v3 vs v4), and the deep internals of the NFS protocol stack. Compare NFS with other network filesystems.

### What You'll Cover
- Performance tuning: `rsize`, `wsize`, `noatime`, and RDMA transport
- `nfsstat` and `nfsiostat` for benchmarking and diagnostics
- pNFS (parallel NFS) layout types: files, objects, blocks
- NFS locking delegation: `nlmclnt`, `rpc.lockd`, and v4 state management
- Comparing NFS vs CIFS/SMB vs GlusterFS vs CephFS
- Deep protocol mechanics: compound operations, session trunking

NFS performance tuning is critical in high-throughput environments like HPC clusters and media servers. The wrong settings can waste 30% or more of available bandwidth.

At this level you will master:

- **rsize/wsize**: These control read/write block sizes. Larger values (1MB for NFSv4) reduce round trips but increase memory usage. NFSv3 defaults to 32KB; NFSv4 can use up to 1MB. Test with `dd` and `nfsiostat`.
- **RDMA transport**: NFS over RDMA (RoCE or InfiniBand) bypasses the TCP stack entirely, reducing latency from microseconds to nanoseconds. Requires RDMA-capable NICs and `mount -o rdma`.
- **pNFS**: Parallel NFS separates metadata from data. The metadata server tells clients directly where data blocks live, allowing parallel I/O without bottlenecks. Layout types: files (file-based striping), blocks (block device mapping), objects (object storage).
- **NFSv4 state**: Unlike NFSv3's stateless design, NFSv4 maintains state for locks, delegations, and sessions. The server can delegate file locks to clients, reducing network round trips. `nlmclnt` handles Network Lock Manager for NFSv3.
- **Protocol comparison**: NFS is simple but Linux-focused. SMB/CIFS works natively with Windows. GlusterFS scales horizontally across nodes. CephFS provides POSIX semantics with distributed object storage. Choose based on your environment.


[← Previous](07-section-4-nfsv4-features.md) | [↑ Index](index.md) | [Next →](09-section-5-nfsv41-and-pnfs.md)
