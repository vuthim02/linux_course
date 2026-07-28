## 🔍 Section 9: smbstatus — View Active Connections

smbstatus shows who is connected, what they're accessing, and what files are locked.

### Basic Usage

```bash
# Show all active connections
smbstatus

# Output:
# Service      pid     Machine       Connected at                    Encryption   Signing
# -------------------------------------------------------------------------------------
# shared       12345   192.168.1.50  Tue Jun 24 10:00:00 2024 CEST   -            AES-128-GCM
#
# Locked files:
# Pid          Uid        DenyMode   Access      R/W        Oplock      SharePath   Name
# -------------------------------------------------------------------------------------
# 12345        1000       DENY_NONE  0x100089    RDONLY     LEASE(RH)   /srv/samba  document.pdf
```

### Output Fields

```
Service        — Name of the Samba share
pid            — smbd child process ID handling this connection
Machine        — Client IP address or hostname
Connected at   — When the session started
Encryption     — Encryption status (yes, no, AES-128-GCM, etc.)
Signing        — SMB signing algorithm (AES-128-GCM, AES-128-CCM, HMAC-SHA256)

Locked files:
Pid            — Process ID holding the lock
Uid            — User ID
DenyMode       — DENY_DOS, DENY_ALL, DENY_READ, DENY_WRITE, DENY_NONE, DENY_FCB
Access         — Bitmask of requested access rights
R/W            — RDONLY, RDWR, WRONLY
Oplock          — Oplock/lease type: EXCLUSIVE, BATCH, LEVEL_II, LEASE(RH), etc.
SharePath      — Filesystem path to the share root
Name           — Path to the locked file relative to share root
```

### Useful Options

```bash
# Show only locks
smbstatus -L

# Show only connections
smbstatus -p

# Don't resolve IPs to hostnames (faster)
smbstatus -n

# Output in machine-readable format
smbstatus -b

# Show shares
smbstatus -S

# Show processes
smbstatus -P
```

### Interpreting SMB Locks

```bash
# If a user reports "file in use" on Windows:
smbstatus -L | grep filename.pdf

# Find which user and machine has the lock
# The output shows: PID, UID, access mode, oplock type

# Close a connection (forceful):
sudo smbcontrol smbd close-share shared

# Kill a specific smbd process (last resort):
sudo smbcontrol smbd shutdown 12345  # by PID
```





[← Previous](12-section-8-smbclient-the-interactive.md) | [↑ Index](index.md) | [Next →](14-section-10-winbind-integrating-windows.md)
