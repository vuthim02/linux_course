## 🔍 Section 5: NFSv4.1 and pNFS

### What pNFS (Parallel NFS) Does

pNFS separates data and metadata paths:

```
Traditional NFS:
  Client <── ALL operations (metadata + data) ──> Server (single bottleneck)

pNFS:
  Client <── Metadata operations ──> Metadata Server (MDS)
  Client <── Data operations ──────> Data Servers (DS) in parallel
```

### pNFS Layout Types

| Layout | Description | Like |
|--------|-------------|------|
| `file` | File-level striping across DS | Traditional striping |
| `object` | Object-based storage devices (OSD) | Rare |
| `block` | Block-level access to SAN (iSCSI, FC) | Like direct disk access |
| `flexfiles` | Flexible files layout (NFSv4.2) | Most flexible |

### How pNFS Works (Protocol Flow)

```bash
# 1. Client sends OPEN to MDS
# 2. MDS returns filehandle + LAYOUT (describes where data is stored)
# 3. Client uses LAYOUT to read/write directly to Data Servers
# 4. All metadata operations still go through MDS
# 5. Client returns LAYOUT (scoped, timed, or revoked)

# The layout is a delegation — client caches it for parallel I/O
```

### Sessions (NFSv4.1)

NFSv4.1 introduces **sessions** — a transport-level mechanism for exactly-once semantics:

```bash
# Each session has:
#   - Session ID
#   - Slot table (for request ordering)
#   - Back channel (server can initiate RPCs to client)

# Sessions provide:
#   - Exactly-once RPC semantics (no duplicate operations)
#   - Trunking (multiple connections per session)
#   - Server-side recovery

# Check if session is active
cat /proc/self/mountstats | grep -A5 "nfs4"
```

### Checking pNFS Support

```bash
# Server: check if pNFS is enabled
cat /proc/fs/nfsd/threads

# Client: check if pNFS layout was granted
cat /proc/self/mountstats | grep "layouts:"

# Enable pNFS on server (kernel config)
sudo modprobe nfsd_layout_nfsv4_files
```

### NFSv4.1 Trunking

Multiple connections between client and server for better throughput:

```bash
# Multiple source ports → same NFS server
# Each TCP connection can use different paths (multi-path)

# Check trunking
cat /proc/net/rpc/use-gss-proxy 2>/dev/null
```





[← Previous](08-level-3-advanced-performance-internals.md) | [↑ Index](index.md) | [Next →](10-section-6-autofs-automatic-nfs.md)
