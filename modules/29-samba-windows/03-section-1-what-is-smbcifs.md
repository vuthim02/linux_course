## 🔍 Section 1: What Is SMB/CIFS?

### From NetBIOS to SMB3

The protocol stack that Windows file sharing runs on has evolved across three major protocol versions:

```
1980s: NetBIOS (Network Basic Input/Output System)
   └─ NetBEUI (NetBIOS Extended User Interface) — non-routable
   └─ NetBIOS over TCP/IP (NBT) — RFC 1001/1002, ports 137/138/139
1990s: SMB1 (CIFS) — Common Internet File System
   └─ Microsoft extension of IBM's original SMB
   └─ Chatty, insecure, many dialects (LANMAN1, LANMAN2, NT LM 0.12)
2006: SMB2 — Windows Vista and Server 2008
   └─ Reduced command count (100+ → 19)
   └─ Pipelining, larger reads/writes
   └─ Signed by default
2012: SMB3 — Windows 8 and Server 2012
   └─ SMB3.0: Encryption, multichannel, RDMA
   └─ SMB3.02: Secure dialect negotiate, improved encryption
   └─ SMB3.1.1: Pre-authentication integrity, stronger hashing
   └─ SMB3.11: Directory leasing, SMB compression
```

### Dialect Negotiation — How It Works Under the Hood

When a client connects to an SMB server, the first exchange is a dialect negotiation:

```
Client → Server: SMB_COM_NEGOTIATE (protocol dialect list)
   "I support: SMB 2.0.2, SMB 2.1, SMB 3.0, SMB 3.02, SMB 3.1.1"

Server → Client: SMB2_NEGOTIATE response
   "Agreed: SMB 3.1.1"
   "Security mode: signing enabled, encryption supported"
   "Max transact size: 1048576"
   "Server GUID: 6a3ce67c-..."
```

Modern Samba and Windows always negotiate the highest common dialect. SMB1 can be explicitly disabled for security.

### Ports and Transport

| Protocol | Transport | Port | Purpose |
|----------|-----------|------|---------|
| NetBIOS name service | UDP/TCP | 137 | Name registration and resolution |
| NetBIOS datagram | UDP | 138 | Unreliable datagram (browsing) |
| NetBIOS session | TCP | 139 | Legacy SMB over NetBIOS |
| Direct SMB (SMB2/3) | TCP | 445 | Modern SMB, no NetBIOS needed |

**Key insight:** Port 445 is the direct SMB transport. Ports 137-139 are NetBIOS over TCP/IP (NBT). On modern networks, only port 445 is strictly necessary, but many Windows clients still attempt NetBIOS name resolution first.

### Protocol Flow — The SMB Session Lifecycle

```
1. TCP CONNECT          → Client opens TCP connection to port 445
2. NEGOTIATE            → Dialect negotiation (version handshake)
3. SESSION SETUP        → Authentication (NTLMSSP or Kerberos)
4. TREE CONNECT         → Connect to a share (\\SERVER\SHARE)
5. CREATE (open)        → Open a file or named pipe
6. READ/WRITE/IOCTL     → File operations
7. CLOSE                → Close the file handle
8. TREE DISCONNECT      → Disconnect from the share
9. LOGOFF               → End the session
```

---



---

[← Previous](02-level-1-basic-smbcifs-concepts.md) | [↑ Index](index.md) | [Next →](04-section-2-samba-overview.md)
