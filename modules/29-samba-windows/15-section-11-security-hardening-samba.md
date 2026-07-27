## 🔍 Section 11: Security — Hardening Samba

### Disabling SMB1 (CIFS)

SMB1 is a security disaster — it lacks signing, encryption, and has known vulnerabilities (EternalBlue, WannaCry).

```ini
[global]
   # Disable SMB1 completely
   server min protocol = SMB2_02
   client min protocol = SMB2_02

   # Or explicitly disable the SMB1 protocol
   disable netbios = yes          # Disable ports 137-139
   smb ports = 445                # Only use direct SMB over TCP 445
```

Verify SMB1 is disabled:

```bash
# Check which protocols are available
testparm -v | grep "server min protocol"
testparm -v | grep "client min protocol"

# Try to connect with SMB1 (should fail)
smbclient -L //server -m NT1
# protocol negotiation failed: NT_STATUS_INVALID_PARAMETER
```

### SMB Signing and Encryption

```ini
[global]
   # SMB3 encryption (strong)
   server smb encrypt = required        # All traffic encrypted
   # or
   server smb encrypt = desired          # Encrypt if client supports
   # or
   server smb encrypt = disabled         # No encryption

   # SMB signing (data integrity)
   server signing = required             # All packets signed
   # or
   server signing = mandatory            # Enforce signing (all dialects)
   # or
   client signing = required             # Client requires signing
```

### Guest Access Risks

```ini
[global]
   # Option 1: Disable guest access entirely
   map to guest = Never

   # Option 2: Only map bad users (typod passwords) to guest
   map to guest = Bad User

   # Option 3: Map bad passwords too (dangerous!)
   map to guest = Bad Password          # NEVER USE THIS
```

### Restrict to Specific Hosts

```ini
[shared]
   hosts allow = 192.168.1. 192.168.2. 127.0.0.1
   hosts deny = 0.0.0.0/0

   # Or use global settings
[global]
   hosts allow = 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16
```

### User and Group Restrictions

```ini
[finance]
   # Only specific users
   valid users = alice, bob, @finance

   # Only at certain times
   # Not a Samba feature — use PAM or at daemon

   # Maximum connections
   max connections = 10

   # Log all access
   veto files = /Thumbs.db/.DS_Store/desktop.ini/
   dont descend = /proc/sys/
```

### Audit and Logging

```ini
[global]
   log level = 2 auth:5
   log file = /var/log/samba/log.%m
   max log size = 5000

   # Audit all file operations
   vfs objects = full_audit
   full_audit:success = all
   full_audit:failure = all
   full_audit:prefix = %u|%I|%m|%S
   full_audit:facility = local5
   full_audit:priority = notice
```

### Firewall Rules

```bash
# Minimal firewall for Samba
sudo iptables -A INPUT -p tcp --dport 445 -j ACCEPT     # SMB direct
sudo iptables -A INPUT -p tcp --dport 139 -j ACCEPT     # NetBIOS session (optional)
sudo iptables -A INPUT -p udp --dport 137 -j ACCEPT     # NetBIOS name (optional)
sudo iptables -A INPUT -p udp --dport 138 -j ACCEPT     # NetBIOS datagram (optional)

# For AD DC (add these):
sudo iptables -A INPUT -p tcp --dport 389 -j ACCEPT     # LDAP
sudo iptables -A INPUT -p tcp --dport 636 -j ACCEPT     # LDAPS
sudo iptables -A INPUT -p tcp --dport 88 -j ACCEPT      # Kerberos
sudo iptables -A INPUT -p udp --dport 88 -j ACCEPT      # Kerberos
sudo iptables -A INPUT -p tcp --dport 464 -j ACCEPT     # kpasswd
sudo iptables -A INPUT -p udp --dport 464 -j ACCEPT     # kpasswd
sudo iptables -A INPUT -p tcp --dport 3268 -j ACCEPT    # Global Catalog
sudo iptables -A INPUT -p tcp --dport 3269 -j ACCEPT    # Global Catalog SSL
sudo iptables -A INPUT -p tcp --dport 53 -j ACCEPT      # DNS TCP
sudo iptables -A INPUT -p udp --dport 53 -j ACCEPT      # DNS UDP
```

---



---

[← Previous](14-section-10-winbind-integrating-windows.md) | [↑ Index](index.md) | [Next →](16-section-12-performance-tuning.md)
