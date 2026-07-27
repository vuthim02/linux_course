## 🧠 Deep Understanding — How NFS Really Works

### The ONC RPC Protocol

NFS is built on Open Network Computing Remote Procedure Calls (ONC RPC). Every NFS operation is an RPC call:

```
RPC Structure:
  +-----------------------+
  | RPC Header:           |
  |   xid (transaction)   |
  |   msg_type (call=0)   |
  |   rpcvers (2)         |
  |   prog (100003=NFS)   |
  |   vers (3 or 4)       |
  |   proc (LOOKUP=3)     |
  |   auth credentials    |
  |   auth verifier       |
  +-----------------------+
  | RPC Body (procedure   |
  | specific data)        |
  +-----------------------+

RPC Reply:
  +-----------------------+
  | RPC Header:           |
  |   xid (same)          |
  |   reply_stat          |
  |   accept_stat         |
  +-----------------------+
  | RPC Body (results)    |
  +-----------------------+
```

### XDR — External Data Representation

All RPC data is serialized using XDR — a binary format that handles:

- **Integer encoding**: Big-endian (network byte order)
- **Variable-length data**: Length prefix + data + padding to 4-byte boundary
- **Strings**: Length + UTF-8 data + null padding
- **Opaque data**: Raw bytes with padding

### XID — Transaction IDs

Each RPC has a unique **transaction ID (xid)** that correlates requests and responses:

```bash
# Client sends RPC with xid=0xABCD1234
# Server replies with xid=0xABCD1234
# Client matches reply to pending request

# If no reply arrives:
#   - Client retries with SAME xid
#   - Server sees duplicate xid → returns cached reply (idempotent operations)
#   - Non-idempotent operations (like MKDIR) may cause issues
#   - NFSv4.1 sessions solve this with exactly-once semantics
```

### The Portmapper (rpcbind) Protocol

For NFSv3, finding services uses the portmapper protocol:

```
Client → portmapper (port 111):
  CALL:  GETPORT(program=100005, version=3, proto=tcp)

Portmapper → Client:
  REPLY: port=40401

Client → mountd (port 40401):
  CALL:  MOUNT(path="/export/data", auth=UNIX(uid=0))

mountd → Client:
  REPLY: filehandle=0x...
```

**The portmapper maintains a table:**
```bash
# View the table
rpcinfo -p

# The table maps:
#   Program number → port
#   Version number → port
#   Protocol (TCP/UDP) → port

# Program numbers (IANA-assigned):
#   100000  portmapper (rpcbind)
#   100001  rstatd
#   100003  nfs
#   100005  mountd
#   100011  rquotad
#   100021  nlockmgr (lockd)
#   100024  statd
```

### How NFSv4 Eliminated Extra Daemons

NFSv4 is a **integrated protocol** — it replaced multiple separate protocols:

```
NFSv3:                   NFSv4:
  rpcbind                  [single port 2049]
  nfsd ─── port 2049       nfsd ─── port 2049 (compound RPCs)
  mountd ─── random port    │
  statd ─── random port      └── Everything is one protocol:
  lockd ─── random port          MOUNT (part of NFSv4)
  rquotad ─── random port        LOCK (part of NFSv4)
                                  STAT (part of NFSv4)
                                  ACL (part of NFSv4)
```

**NFSv4 compound RPCs** merge multiple operations:

```bash
# NFSv3 would need:
#   1. PORTMAP GETPORT(mountd)   → port 38429
#   2. MOUNT("/export/data")     → fh1
#   3. LOOKUP(fh1, "file.txt")   → fh2
#   4. OPEN(fh2, RDONLY)         → stateid
#   5. READ(stateid, 0, 4096)    → data
#   6. CLOSE(stateid)
#   7. PORTMAP GETPORT(statd)    → port 43987
#   8. LOCK(fh2, WRITE, ...)     (etc)

# NFSv4 sends ONE compound:
#   PUTFH(fh_root)
#   LOOKUP("export/data")
#   LOOKUP("file.txt")
#   OPEN(RDONLY)
#   READ(0, 4096)
#   CLOSE
# All in a SINGLE RPC call on port 2049
```

This is why NFSv4 is dramatically more efficient for metadata operations — one RTT instead of many.

### The Filehandle

The **filehandle** is the fundamental identifier in NFS — it's the server's internal reference to a file or directory:

```
NFSv3 filehandle (32 bytes):
  +------+------+------+------+
  | fsid | inode| gen  | pad  |
  +------+------+------+------+

  - fsid:  filesystem identifier
  - inode: inode number on disk
  - gen:   generation counter (changes on file deletion/recreation)

NFSv4 filehandle (variable, up to 128 bytes):
  +------+------+------+------+--------+
  | fsid | inode| gen  | type  | domain |
  +------+------+------+------+--------+

  - type: file, dir, symlink, etc.
  - domain: auth domain for NFSv4

```

**The filehandle is opaque to the client** — the client cannot interpret its contents. It just stores and presents the filehandle in subsequent RPCs.

### How close-to-open Consistency Works

NFSv3 provides **close-to-open consistency** — the most important behavioral guarantee:

```
Client A:
  1. OPEN("/file.txt")
  2. READ → caches data in page cache
  3. (no server contact for subsequent reads)
  4. WRITE → caches in page cache
  5. CLOSE → flushes ALL cached writes to server
            → sends GETATTR to verify timestamps

Client B (after Client A's close):
  1. OPEN("/file.txt")
     → Server has latest data
     → GETATTR returns fresh attributes
  2. Client B sees Client A's changes

The guarantee: after close(), subsequent open() by ANY client
sees the latest data — because close() flushed everything.
```

**Without CLOSE, there is NO guarantee:**

```
Client A opens file but never closes:
  - Writes stay in Client A's page cache
  - No flush has occurred
  - Client B sees old data
  - If Client A crashes: data loss
```

**This is why NFSv3 has no server-side byte-range locking guarantee** — there is no mandatory byte-range lock protocol in the NFS protocol itself. Separate lockd handles that.

### NFSv4 Delegations — Beyond close-to-open

NFSv4 adds **delegations** for better performance:

```
READ delegation:
  Server says: "Nobody else is writing this file — cache freely"
  Client benefits:
    - No GETATTR on every open
    - No close-to-open check
  Server can RECALL delegation when another client writes:
    Client A ← DELEGRECALL ← Server ← OPEN(write) ← Client B
    Client A flushes dirty pages → returns delegation

WRITE delegation:
  Server says: "You're the only writer — buffer locally"
  Client benefits:
    - No flush on every close
    - Local caching without server round trips
  Server recalls on conflict.

Delegation types:
  - READ delegation (any number of clients)
  - WRITE delegation (single client, exclusive)
  - No delegation (default for NFSv3 behavior)
```

### Attribute Caching

NFS clients cache file attributes (size, mtime, permissions) with a **timeout**:

```bash
# Kernel-side attribute cache parameters:
#   acregmin  = minimum attribute cache time for regular files (default 3s)
#   acregmax  = maximum attribute cache time for regular files (default 60s)
#   acdirmin  = minimum attribute cache time for directories (default 30s)
#   acdirmax  = maximum attribute cache time for directories (default 60s)

# Mount with noac to disable attribute caching entirely:
sudo mount -t nfs4 -o noac localhost:/export/nfs/data /mnt/nfs_test
# WARNING: Very slow — every stat() goes to the server
```

**The attribute cache state machine:**
```
1. Client caches attrs with timestamp
2. Time passes...
3. If cache is "young" (< acregmin): use cached (no RPC)
4. If cache is "medium" (acregmin - acregmax): check GETATTR (one RPC)
5. If cache is "expired" (> acregmax): treat as stale, GETATTR on next access
6. If another client modified → no notification in NFSv3
   NFSv4: delegations handle this better
```

### The Linux VFS-NFS Integration

The Linux Virtual File System (VFS) translates every POSIX call into NFS operations:

```
User: ls -l /mnt/nfs/file.txt
       |
POSIX calls:
  stat("/mnt/nfs/file.txt")
       |
VFS layer:
  Finds nfs4_file_inode_operations
       |
NFS client (kernel):
  nfs_getattr() → nfs4_proc_getattr()
       |
RPC layer (sunrpc):
  Encodes: PUTFH + GETATTR compound
  Sends to server:2049
       |
Network
       |
Server:
  nfsd_decode_args()
  nfsd_getattr()
  nfsd_encode_result()
       |
Reply
```

### NFS and the Page Cache

NFS integrates with the Linux page cache in a special way:

```bash
# Dirty pages on NFS are tracked differently than local filesystems
# NFS writes go through:
#   1. Page cache write (fast, local)
#   2. VM flushes dirty pages to NFS server (pdflush/flusher threads)
#   3. Server commits to disk (if sync export)

# Key difference from local filesystem:
#   - NFS write-back cache is time-based (not page-count-based)
#   - Default commit interval: ~5 seconds (or on close())
#   - sync/fsync forces immediate commit to server

# Check NFS writeback statistics
cat /proc/self/mountstats | grep -A5 "nfs"
```

### The RPC Layer: sunrpc

The Linux kernel's RPC implementation (`sunrpc.ko`) handles all NFS transport:

```
sunrpc layer components:
  - rpc_clnt: RPC client handle (per mount)
  - rpc_task: individual RPC operation
  - rpc_xprt: transport (TCP socket, RDMA, etc.)
  - rpc_wait_queue: request ordering

Flow:
  1. NFS operation → rpc_task created
  2. Task added to xprt's queue
  3. xprt sends RPC over TCP
  4. Reply received → task completed
  5. Callback to NFS layer with results

Transport states:
  - connected: TCP established
  - connecting: TCP handshake in progress
  - close_wait: TCP disconnection detected
  - bound: bound to port (after rpcbind)
```

### NFSv4 Lease and State Model

NFSv4 state management is lease-based:

```
Timeline:
  t=0:  Client opens file → server creates state (lease: 90s)
  t=10: Client reads
  t=20: Client writes
  t=30: Client renews lease (via RENEW or any operation)
  t=40: Client gets lock
  t=90: Deadline of original lease, but RENEW at t=30 extends it
  t=120: Client crashes (no more RENEW)
  t=210: Lease expires (120 + 90 = 210)
         Server revokes ALL state for this client:
           - Closes open files
           - Releases locks
           - Recalls delegations
  t=211: Client B can now lock the file that Client A had locked
```

**Lease types:**
```
open_owners: who has files open?
lock_owners: who holds locks?
delegations: who has delegated control?

Each has a stateid, and each stateid expires with the lease.
```

### NFSv4.1 Sessions — Solving Exactly-Once Semantics

Before sessions, NFSv4 had a problem with **non-idempotent operations**:

```
Problem (NFSv4.0):
  Client sends: CREATE(file)
  Server creates file, sends reply
  Reply LOST on network
  Client retries: CREATE(file)  ← which one is this?
  Server: "file already exists" → NFS4ERR_EXIST
  Client: "did my create succeed or not?" → AMBIGUOUS

Solution (NFSv4.1 sessions):
  1. Client creates a session with N slot table entries
  2. Each RPC gets a slot + sequence ID
  3. Server tracks: "I've seen slot 3, seq 5 — it was a CREATE, it succeeded"
  4. Reply cached in slot
  5. Client retries slot 3, seq 5 → server returns CACHED reply
  6. Client knows: "create succeeded!"

Session slot table:
  +-------+------+-----------+----------+
  | Slot  | Seq  | Operation | Cached?  |
  +-------+------+-----------+----------+
  | 0     | 42   | READ      | no (done)|
  | 1     | 7    | OPEN      | yes      |
  | 2     | 19   | WRITE     | no (done)|
  | 3     | 5    | CREATE    | yes      | ← reply cached for retransmit
  +-------+------+-----------+----------+
```

### What Happens During NFS Server Crash and Recovery

```
Server crash timeline:
  t=0: Server running
  t=10: Server crashes
         Clients see: "RPC: timed out" (TCP retransmits)
         Clients keep retrying with increasing intervals
  t=15: Server comes back
         nfsd starts, new boot verifier
  t=16: Client X sends: READ(fh, stateid)
         Server: "Unknown stateid" → NFS4ERR_STALE_STATEID
  t=17: Client X: OPEN file → new stateid → re-read
  t=20: All clients have re-established state

NFSv3 recovery (simpler, stateless):
  t=10: Server crashes
         Clients retry: READ(fh) — no stateid needed
  t=15: Server comes back
         Client X retries: READ(fh) ← it just works!
         (Server doesn't track anything — filehandle is enough)
         Only locks need recovery (via statd/lockd)
```

---



---

[← Previous](16-practice-section-15-hands-on-exercises.md) | [↑ Index](index.md) | [Next →](18-summary-complete-command-reference-for.md)
