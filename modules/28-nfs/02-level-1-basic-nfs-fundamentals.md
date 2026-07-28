## ⭐ Level 1: Basic — NFS Fundamentals and Installation

![NFS Protocol Diagram](https://upload.wikimedia.org/wikipedia/commons/thumb/6/69/NFS_Usage_Example.svg/220px-NFS_Usage_Example.svg.png)  
*NFS enables remote file sharing across a network. Image credit: Wikimedia Commons.*

> **Level 1 Goal:** Understand the NFS protocol — RPC, XDR, portmapper, and the differences between NFSv3, NFSv4, NFSv4.1, and pNFS. Install and verify the NFS server on your system.

### What You'll Cover
- How NFS works: RPC, XDR encoding, and the portmapper service
- NFS protocol versions: v3, v4, v4.1, and v4.2 compared
- NFSv4 pseudo-filesystem and stateful operations
- Installing and verifying the NFS server (nfs-utils / nfs-kernel-server)
- Key daemons: `rpcbind`, `nfsd`, `mountd`, `lockd`, `statd`
- Checking NFS status with `rpcinfo` and `showmount`

NFS (Network File System) allows a Linux server to share directories over the network as if they were local. Clients mount remote filesystems and access files transparently.

At this level you will learn:

- **RPC and XDR**: NFS uses Remote Procedure Calls (RPC) over TCP/UDP port 2049. XDR (External Data Representation) encodes data so different architectures can communicate. `rpcbind` maps RPC program numbers to port numbers.
- **Protocol versions**: NFSv3 is stateless and fast but lacks security. NFSv4 uses a single TCP port (2049), supports Kerberos authentication, and is stateful. NFSv4.1 adds pNFS for parallel access. NFSv4.2 adds server-side copy and sparse files.
- **Installation**: On RHEL/CentOS: `dnf install nfs-utils`. On Ubuntu/Debian: `apt install nfs-kernel-server`. Start with `systemctl enable --now nfs-server`.
- **Verification**: `rpcinfo -p` lists all registered RPC services. `showmount -e server` lists exports. `nfsstat -s` shows server statistics. If these commands fail, the NFS server is not running.


[← Previous](01-what-you-will-achieve-in.md) | [↑ Index](index.md) | [Next →](03-section-1-what-is-nfs.md)
