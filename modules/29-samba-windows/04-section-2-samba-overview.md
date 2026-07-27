## 🔍 Section 2: Samba Overview

### The Samba Suite

Samba is not a single daemon — it's a suite of components:

| Component | Purpose |
|-----------|---------|
| **smbd** | SMB/CIFS service daemon — file and print sharing |
| **nmbd** | NetBIOS name service daemon — name resolution, browsing |
| **winbindd** | Winbind daemon — integrates Windows users/groups into Linux |
| **samba** | Combined daemon for AD DC mode (replaces smbd+nmbd+winbindd) |
| **smbclient** | FTP-like SMB client |
| **smbstatus** | List active SMB connections |
| **testparm** | Validate smb.conf syntax |
| **smbpasswd** | Manage SMB password database |
| **pdbedit** | Manage the Samba user database |
| **net** | Tool for joining domains, managing shares, RPC calls |
| **wbinfo** | Query Winbind's user/group database |

### smbd and nmbd Lifecycle

```
Startup:
  smbd reads smb.conf → opens port 445 (and 139) → forks children to handle connections
  nmbd reads smb.conf → registers NetBIOS name → starts browsing services

Connection handling:
  smbd listens on TCP 445 → accepts connection → spawns child process
  Each smbd child handles one SMB session
  Authentication → tree connect → file operations → disconnect

Shutdown:
  SIGTERM to smbd → clean close all connections → release locks → exit
```

### smb.conf — The Brain of Samba

The primary configuration file is `/etc/samba/smb.conf`. All Samba behavior is controlled here.

```
smb.conf structure:
  ┌─────────────────────────────────────┐
  │ [global]        # Global settings   │
  │   workgroup = WORKGROUP             │
  │   server string = File Server       │
  │   security = user                   │
  │   ...                               │
  ├─────────────────────────────────────┤
  │ [homes]         # Auto-share home   │
  │   comment = Home Directories        │
  │   browseable = no                   │
  │   valid users = %S                  │
  │   ...                               │
  ├─────────────────────────────────────┤
  │ [shared]        # Custom share      │
  │   path = /srv/samba/shared          │
  │   read only = no                    │
  │   guest ok = yes                    │
  │   ...                               │
  └─────────────────────────────────────┘
```

### testparm — Validate Before You Reload

```bash
# Validate the configuration
testparm

# Verbose output (shows all defaults)
testparm -v

# Output in SMB.conf format (useful for debugging)
testparm --parameter-name "security"

# Check a specific share
testparm -s --section-name "shared"
```

### Config File Search Order

```bash
# Default location
/etc/samba/smb.conf

# Check which file smbd is actually using
smbd -b | grep "CONFIGFILE"

# Override with -s flag
smbd -s /path/to/custom/smb.conf
```

---



---

[← Previous](03-section-1-what-is-smbcifs.md) | [↑ Index](index.md) | [Next →](05-level-2-intermediary-file-serving.md)
