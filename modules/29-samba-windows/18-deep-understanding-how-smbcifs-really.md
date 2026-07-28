## 🧠 Deep Understanding — How SMB/CIFS Really Works

### The SMB Protocol Flow — Byte by Byte

When a Windows client connects to a Samba share, the following sequence occurs at the protocol level:

```
Phase 1: TCP CONNECTION
   Client (port 49152) → Server (port 445)
   TCP three-way handshake (SYN, SYN-ACK, ACK)

Phase 2: NEGOTIATE PROTOCOL
   Client sends SMB2 Negotiate request:
   ├── ProtocolId: 0x424D53FE (\xfeSMB)
   ├── StructureSize: 36
   ├── DialectCount: 5
   ├── Dialects: [SMB 2.0.2, SMB 2.1, SMB 3.0, SMB 3.02, SMB 3.1.1]
   └── Capabilities: [DFS, Encryption, Leasing]

   Server responds SMB2 Negotiate response:
   ├── ProtocolId: 0x424D53FE
   ├── StructureSize: 65
   ├── DialectRevision: 0x0311 (SMB 3.1.1)
   ├── SecurityMode: Signing enabled
   ├── ServerGuid: {6a3ce67c-...}
   ├── Capabilities: [DFS, Encryption, Leasing, Multichannel]
   ├── MaxTransactSize: 1048576
   ├── MaxReadSize: 1048576
   ├── MaxWriteSize: 1048576
   ├── CipherCount: 2
   ├── Ciphers: [AES-128-GCM, AES-128-CCM]
   ├── HashCount: 1
   └── Hash: [SHA-512]
   └── SecurityBuffer: [NTLMSSP or SPNEGO token]

Phase 3: SESSION SETUP (Authentication)
   If Kerberos:
   ├── Client sends SPNEGO with Kerberos ticket
   └── Server validates ticket against KDC

   If NTLMSSP:
   ├── Client sends NTLMSSP_NEGOTIATE
   ├── Server responds with NTLMSSP_CHALLENGE (8-byte nonce)
   ├── Client responds with NTLMSSP_AUTH (hashed password + nonce)
   └── Server validates hash

Phase 4: TREE CONNECT
   Client → SMB2 TreeConnect Request:
   ├── Path: \\SERVER\sharename
   └── Flags: none

   Server → SMB2 TreeConnect Response:
   ├── ShareType: DISK (0x01)
   ├── ShareFlags: DFS, ContinuousAvailability
   ├── Capabilities: DFS, Asynchronous, Large MTU
   └── MaximalAccess: 0x001F01FF (nearly all rights)

Phase 5: FILE OPERATIONS (CREATE, READ, WRITE, CLOSE)
   SMB2 Create Request:
   ├── DesiredAccess: 0x001F01FF (GENERIC_ALL)
   ├── FileAttributes: NORMAL
   ├── ShareAccess: READ | WRITE
   ├── CreateDisposition: OPEN_IF (open or create)
   ├── CreateOptions: FILE_NON_DIRECTORY_FILE
   └── Name: "document.pdf"

   SMB2 Create Response:
   ├── FileId (Persistent + Volatile): 128-bit handle
   ├── CreateAction: FILE_OPENED
   ├── AllocationSize: 0
   ├── EndOfFile: 1048576
   ├── FileAttributes: NORMAL
   └── OplockLevel: LEASE(RH) (Read/Handle caching)

Phase 6: DISCONNECT
   SMB2 TreeDisconnect → SMB2 Logoff → TCP RST
```

### NetBIOS vs Direct Hosting

Before SMB ran directly on TCP port 445, it ran on top of NetBIOS:

```
Legacy Path (Windows 9x/2000):
   SMB → NetBIOS Session Service → TCP 139
            ├── NetBIOS Name Service (UDP 137)
            └── NetBIOS Datagram Service (UDP 138)

Modern Path (Windows XP+):
   SMB2/3 → TCP 445 (Direct TCP transport)
   No NetBIOS required
   Larger MTU support (no NetBIOS header overhead)

The transformation:
   NetBIOS header: 4 bytes (Type, Flags, Length)
   vs
   Direct SMB header: Minimal framing in TCP stream
```

NetBIOS name resolution works like this:

```
1. Client checks local NetBIOS name cache
2. Client sends broadcast: "Who has name FILESERVER?"
3. WINS server (if configured) responds with IP
4. Or: LMHOSTS file is checked
5. Or: DNS fallback (modern)
```

### SMB2/3 Credit System

SMB2 introduced a credit-based flow control system that replaced the serial request/response of SMB1.

```
How credits work:
┌─────────────────────────────────────────────────┐
│ 1. Negotiation: Server grants initial credits    │
│    Client receives: 16 credits                   │
│                                                   │
│ 2. Client sends request, deducts credits:         │
│    [Read request: 1 credit] credits_remaining=15 │
│                                                   │
│ 3. Server grants more credits in response:        │
│    [Response: credits_granted=4] remaining=19     │
│                                                   │
│ 4. Client can pipeline multiple requests:         │
│    [Read #1, Read #2, Write #1] = 3 credits       │
│    All in-flight without waiting for responses    │
│                                                   │
│ 5. If client runs out of credits, it must WAIT    │
│    until server grants more in responses          │
└─────────────────────────────────────────────────┘
```

Benefits of the credit system:
- **Pipelining**: Multiple requests in flight without ordering constraints
- **Flow control**: Server controls client send rate
- **Efficiency**: No round-trip overhead for sequential operations
- **Scaling**: Large I/O operations can consume multiple credits per request

### Oplocks and Leases

Opportunistic locks (oplocks) are SMB's mechanism for client-side caching:

```
Oplock Types:
┌────────────────────────────────────────────────────┐
│  LEVEL_II (Read Caching)                          │
│  ├── Multiple clients can hold LEVEL_II           │
│  └── Client caches reads but not writes           │
│                                                    │
│  EXCLUSIVE (Read + Write Caching)                 │
│  ├── Only ONE client can hold EXCLUSIVE           │
│  ├── Client caches reads AND writes locally       │
│  └── Server must notify if another client opens   │
│                                                    │
│  BATCH (Full Caching + Handle Caching)            │
│  ├── Client caches the file handle too            │
│  ├── Client can close/reopen without server       │
│  └── Maximum performance for single-client access │
│                                                    │
│  LEASE (SMB2/3 Replacement for Oplocks)           │
│  ├── RH: Read + Handle caching                    │
│  ├── R: Read caching only                         │
│  ├── H: Handle caching only                       │
│  └── None: No caching                             │
└────────────────────────────────────────────────────┘

Break sequence:
   Client A holds EXCLUSIVE oplock on file.txt
   Client B opens file.txt
   Server sends Oplock Break to Client A: LEVEL_II
   Client A flushes writes, acknowledges break
   Server opens file for Client B
   Both clients now hold LEVEL_II (read caching only)
```

### SMB3 Multichannel — How It Works

Multichannel allows a single SMB session to use multiple TCP connections:

```
Client (2 NICs)                        Server (2 NICs)
┌─────────────┐                     ┌─────────────┐
│ NIC1: 10.1.1.1 ├─── TCP #1 ──────>│ NIC1: 10.1.1.2 │
│             │                     │             │
│ NIC2: 10.2.1.1 ├─── TCP #2 ──────>│ NIC2: 10.2.1.2 │
└─────────────┘                     └─────────────┘
       │                                    │
       └──────── Session ID: 0xABCD ────────┘
            Same authentication, same session
            File operations striped across both connections

Benefits:
├── Throughput: Near line-rate of both NICs combined
├── Fault tolerance: Survives one NIC failure
└── RDMA support: Direct memory access for ~100 Gbps
```





[← Previous](17-practice-section-15-hands-on-exercises.md) | [↑ Index](index.md) | [Next →](19-summary-complete-command-reference-for.md)
