## 🔍 Section 1: What Is NFS?

**Network File System (NFS)** is a distributed file system protocol originally developed by Sun Microsystems in 1984. It allows a client machine to access files over a network as if they were on local storage.

### Core Concepts

At its heart, NFS is built on three technologies:

1. **RPC (Remote Procedure Call)** — The client calls a function on the server: `LOOKUP("/home/user/file.txt")` → server returns a filehandle.
2. **XDR (External Data Representation)** — A standard way to serialize data so machines with different architectures (big-endian vs little-endian) can communicate.
3. **The Mount Protocol** — Before NFSv4, a separate `mountd` daemon handled the initial handshake: the client sends the path, server returns a filehandle.

```
Client                                Server
  |                                     |
  |--  RPC call: MOUNT("/export/data")  |
  |                                     |
  |<---- RPC reply: filehandle fh=0x--- |
  |                                     |
  |--  RPC call: LOOKUP(fh, "file.txt") |
  |                                     |
  |<---- RPC reply: fh=0x456 ----------- |
  |                                     |
  |--  RPC call: READ(fh, offset, len)  |
  |                                     |
  |<---- RPC reply: [file data] -------- |
```

### NFS Protocol Versions

| Version | Key Characteristics | Status |
|---------|-------------------|--------|
| **NFSv2** (1984) | UDP only, 32-bit file offsets, 2GB max file size | **Obsolete** |
| **NFSv3** (1995) | TCP+UDP, 64-bit offsets, async writes, 64-bit filesizes, separate mount+lock daemons | **Widely used** |
| **NFSv4** (2000) | TCP mandatory, single protocol port (2049), no separate mountd/lockd, stateful, compound RPCs, ACLs, UTF-8 | **Modern standard** |
| **NFSv4.1** (2010) | pNFS (parallel NFS), sessions (exactly-once semantics), referral support | **Latest major** |
| **NFSv4.2** (2016) | Server-side copy (copy_file_range), sparse files, space reservation | **Recent** |

### Stateless vs Stateful

**NFSv3 is mostly stateless:**
- The server does NOT track what files clients have open
- If the server reboots, clients reconnect and retry — no "open state" to lose
- Locks are handled by separate daemons (rpc.statd, rpc.lockd) — they are the *stateful* part
- Server crash recovery: client just retries RPCs until server comes back

**NFSv4 is stateful:**
- The server tracks open files, locks, and delegations
- Uses a **lease** system: clients must renew leases or server revokes state
- If server reboots, all state is lost and clients must re-establish
- The `OPEN` operation creates state on the server
- **Clients detect server reboot** via the `LEASE_MOVED` or `STALE_STATEID` error
- Recovery: clients use `OPEN_CONFIRM`, `LOCK` operations with special recovery flags

```bash
# Check which NFS version is in use
mount | grep nfs
# Output example:
# 192.168.1.100:/export/nfs on /mnt/nfs type nfs4 (rw,relatime,vers=4.2)
```





[← Previous](02-level-1-basic-nfs-fundamentals.md) | [↑ Index](index.md) | [Next →](04-level-2-intermediary-nfs-server.md)
