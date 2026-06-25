# 🐧 Linux System Administrator — Complete Course
## Part 29 of ∞: Samba and Windows Interoperability — SMB/CIFS File Sharing with Linux

---

> **Reverse Engineering Approach:** Samba started when Andrew Tridgell reverse-engineered the SMB (Server Message Block) protocol used by Microsoft Windows — without any documentation, using only a packet sniffer. He discovered that SMB was a dialect of NetBIOS, implemented it in a program called "SMBserver" for his own network, and later realized it worked with Windows. That program became Samba. Today, Samba provides seamless file and print services between Linux and Windows by implementing the SMB/CIFS protocol stack from the ground up. Understanding Samba means understanding how Windows networking actually works — NetBIOS name resolution, browser elections, domain logins, ACL mapping, and the evolution from SMB1 through SMB3.1.1.

---

## 🎯 What You Will Achieve in Part 29

| Level | Focus | Skills Gained |
|-------|-------|--------------|
| **⭐ Level 1: Basic** | SMB/CIFS Concepts & Samba Overview | Understand the SMB protocol evolution (SMB1/2/3), Samba suite architecture, and basic installation |
| **⭐ Level 2: Intermediary** | File Server & Domain Member | Configure standalone shares, join a domain, mount CIFS shares, use smbclient/smbstatus, integrate with Winbind |
| **⭐ Level 3: Advanced** | AD DC, Security & Performance | Deploy Samba as AD DC, harden SMB encryption/signing, tune performance with multichannel and socket options |

Complete **15 hands-on practices** across all levels.

---

## ⭐ Level 1: Basic — SMB/CIFS Concepts and Samba Overview

![SMB Protocol Evolution](https://upload.wikimedia.org/wikipedia/commons/thumb/a/a1/Samba_logo.svg/220px-Samba_logo.svg.png)  
*The Samba logo — bridging Linux and Windows file sharing. Image credit: Wikimedia Commons.*

> **Level 1 Goal:** Understand the SMB/CIFS protocol family — its history, dialect negotiation (SMB1, SMB2, SMB3), and how the Samba suite (smbd, nmbd, winbindd) implements the protocol on Linux.

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

## ⭐ Level 2: Intermediary — File Serving, Domain Membership, and Client Tools

![Samba Standalone Server](https://upload.wikimedia.org/wikipedia/commons/thumb/5/55/Client-server_model.svg/220px-Client-server_model.svg.png)  
*Samba follows a client-server model for file sharing. Image credit: Wikimedia Commons.*

> **Level 2 Goal:** Configure Samba as a standalone file server and domain member. Mount CIFS shares on Linux, use smbclient for transfers, monitor connections with smbstatus, and integrate Windows users via Winbind.

## 🔍 Section 3: Samba as Standalone File Server

This is the most common use case — a Linux server providing file shares to Windows clients (or other Linux clients via SMB).

### Minimal Standalone Configuration

```ini
[global]
   workgroup = WORKGROUP
   server string = %h Samba Server
   netbios name = FILESERVER
   security = user
   map to guest = Bad User
   dns proxy = no

[shared]
   comment = Public Share
   path = /srv/samba/shared
   read only = no
   guest ok = yes
   browseable = yes
   create mask = 0755
   directory mask = 0755
```

### Share Definition Directives Explained

```ini
[sharename]
   # ESSENTIAL
   path = /path/to/share           # Directory on disk to share
   comment = Human description     # Seen in Windows Explorer

   # ACCESS CONTROL
   valid users = user1, user2      # Who can access (space/comma separated)
   invalid users = user3           # Explicitly denied
   read list = user4, @group1      # Read-only for these users/groups
   write list = user5, @group2     # Writable for these users/groups
   admin users = root              # Treated as root (careful!)

   # GUEST ACCESS
   guest ok = yes                  # Allow guest (anonymous) access
   guest only = yes                # Force guest even if credentials provided
   map to guest = Bad User         # Global: map unknown users to guest
   # map to guest options: Never, Bad User, Bad Password

   # PERMISSIONS
   read only = no                  # Writable share
   browseable = yes                # Visible in network browser
   hidden = no                     # Hidden even if browseable=yes (Windows)
   create mask = 0644              # File permission mask after creation
   directory mask = 0755           # Directory permission mask
   force create mode = 0644        # OR with create mask (always set these bits)
   force directory mode = 0755     # OR with directory mask

   # INHERITANCE
   inherit permissions = yes       # Inherit from parent directory
   inherit owner = yes             # New files owned by share directory owner
   inherit acls = yes              # Inherit ACLs from parent

   # OTHER
   veto files = /*.tmp/*.log/      # Hide these files
   delete veto files = yes         # Delete vetoed files on directory delete
   hide unreadable = yes           # Hide files user can't read
   hide unwriteable files = yes    # Hide files user can't write
```

### Setting Up User-Level Security

```bash
# 1. Create Linux users
sudo useradd -m -s /usr/sbin/nologin alice
sudo useradd -m -s /usr/sbin/nologin bob

# 2. Create Samba passwords (separate from Linux passwords!)
sudo smbpasswd -a alice
# New SMB password: ********
# Retype new SMB password: ********
# Added user alice.

sudo smbpasswd -a bob

# 3. View the password database
sudo pdbedit -L
# alice:1000:alice
# bob:1001:bob

# 4. Show detailed user info
sudo pdbedit -L -v alice
```

### Samba Password Storage

```
# Default backend: tdbsam (trivial database)
# Stored in: /var/lib/samba/private/passdb.tdb

# Older backends:
#   smbpasswd: /etc/samba/smbpasswd (plain text, legacy)
#   ldapsam:   LDAP directory

# To see which backend is active:
testparm -s --parameter-name "passdb backend" 2>/dev/null
```

### Complete Share Example: Department Shares

```ini
[global]
   workgroup = COMPANY
   server string = File Server
   security = user
   map to guest = Never
   log file = /var/log/samba/log.%m
   max log size = 50

[finance]
   comment = Finance Department
   path = /srv/samba/finance
   valid users = @finance, alice (manager)
   read only = no
   create mask = 0660
   directory mask = 0770
   browseable = no           # Hidden from browsing, need path

[engineering]
   comment = Engineering Team
   path = /srv/samba/engineering
   valid users = @engineers
   read only = no
   create mask = 0664
   directory mask = 0775

[public]
   comment = Company Public
   path = /srv/samba/public
   guest ok = yes
   read only = no
   create mask = 0644
   directory mask = 0755
```

### Directories and Permissions

```bash
# Create the share directories
sudo mkdir -p /srv/samba/{finance,engineering,public}

# Set group ownership
sudo groupadd finance
sudo groupadd engineers
sudo usermod -aG finance alice
sudo usermod -aG engineers bob

# Set filesystem permissions that match Samba masks
sudo chown root:finance /srv/samba/finance
sudo chmod 2770 /srv/samba/finance       # 2 = setgid: new files inherit group

sudo chown root:engineers /srv/samba/engineering
sudo chmod 2775 /srv/samba/engineering

sudo chown nobody:nogroup /srv/samba/public
sudo chmod 2775 /srv/samba/public
```

---

## 🔍 Section 4: Samba as Domain Member

In this configuration, Samba joins an existing Active Directory domain and authenticates users via Kerberos against Windows Domain Controllers.

### Prerequisites

```bash
# 1. Install required packages
sudo apt install samba krb5-user winbind       # Debian/Ubuntu
sudo dnf install samba krb5-workstation winbind # RHEL/Fedora

# 2. Configure DNS — the AD domain must be resolvable
# Your Linux server's DNS must point to the AD DNS server
cat /etc/resolv.conf
# search ad.company.com
# nameserver 192.168.1.10   (AD DC IP)

# 3. Synchronize time with the Domain Controller
sudo apt install chrony   # or ntpdate
# Kerberos requires time sync within 5 minutes (ideally < 1 min)
sudo chronyd -q 'pool dc01.ad.company.com iburst'
```

### Kerberos Configuration

```ini
# /etc/krb5.conf
[libdefaults]
   default_realm = AD.COMPANY.COM
   dns_lookup_realm = true
   dns_lookup_kdc = true
   ticket_lifetime = 24h
   renew_lifetime = 7d
   forwardable = true

[realms]
   AD.COMPANY.COM = {
      kdc = dc01.ad.company.com
      kdc = dc02.ad.company.com
      admin_server = dc01.ad.company.com
   }

[domain_realm]
   .ad.company.com = AD.COMPANY.COM
   ad.company.com = AD.COMPANY.COM
```

### Join the Domain

```bash
# 1. Test Kerberos connectivity
kinit administrator@AD.COMPANY.COM
# Password: ********

klist
# Ticket cache: FILE:/tmp/krb5cc_0
# Default principal: administrator@AD.COMPANY.COM
# Valid starting: 2024-06-24 10:00:00
# Expires: 2024-06-25 10:00:00

# 2. Configure Samba for domain membership
sudo tee /etc/samba/smb.conf << 'EOF'
[global]
   workgroup = AD
   realm = AD.COMPANY.COM
   security = ADS
   kerberos method = secrets and keytab
   client signing = yes
   client use spnego = yes

   # winbind
   idmap config * : backend = tdb
   idmap config * : range = 10000-19999
   idmap config AD : backend = rid
   idmap config AD : range = 20000-29999

   winbind use default domain = yes
   winbind offline logon = false
   winbind enum users = yes
   winbind enum groups = yes
   winbind refresh tickets = yes

   # template shell
   template shell = /bin/bash
   template homedir = /home/%D/%U

   # logging
   log file = /var/log/samba/log.%m
   log level = 1
EOF

# 3. Join the domain
sudo net ads join -U administrator
# Using short domain name -- AD
# Joined 'FILESERVER' to dns domain 'ad.company.com'

# 4. Verify the computer object in AD
sudo net ads testjoin
# Join is OK
```

### Domain Member smb.conf Explained

```ini
[global]
   security = ADS
   # This tells Samba to use Active Directory (Kerberos + LDAP)
   # instead of its own local password database

   realm = AD.COMPANY.COM
   # The Kerberos realm — MUST be uppercase

   workgroup = AD
   # The NetBIOS domain name (short form, typically uppercase)

   kerberos method = secrets and keytab
   # Options: secrets only, keytab only, secrets and keytab
   # Default: Store the machine account password in secrets.tdb
   # and optionally export to keytab

   idmap config * : backend = tdb
   # Default domain (*) maps to local TDB

   idmap config AD : backend = rid
   # AD domain uses RID algorithm (computes UID/GID from SID)
   # No central mapping file needed — deterministic
   # Alternative: idmap_ldap, idmap_ad, idmap_rfc2307

   winbind use default domain = yes
   # Authenticate as "user" instead of "DOMAIN\user"
```

### Start Winbind

```bash
sudo systemctl enable --now winbind smbd nmbd

# Check winbind status
wbinfo -p
# Ping to winbindd succeeded

# Check domain membership
wbinfo -t
# checking the trust secret for domain AD via RPC calls succeeded

# List domain users
wbinfo -u
# administrator
# alice
# bob
# ...
```

---

## ⭐ Level 3: Advanced — AD DC, Security Hardening, and Performance Tuning

![Samba AD DC](https://upload.wikimedia.org/wikipedia/commons/thumb/0/0f/Active_Directory_Domain_Controller.svg/220px-Active_Directory_Domain_Controller.svg.png)  
*Samba as an Active Directory Domain Controller. Image credit: Wikimedia Commons.*

> **Level 3 Goal:** Deploy Samba as an Active Directory Domain Controller (samba-ad-dc). Harden SMB encryption, signing, and protocol versions. Tune performance with socket options and SMB multichannel. Understand NT4-style PDC legacy deployment.

## 🔍 Section 5: Samba as NT4-style PDC/DC (Legacy)

Before Active Directory, Windows NT domains used a "Primary Domain Controller" (PDC) with "Backup Domain Controllers" (BDCs). Samba 3.x could act as an NT4-style PDC. This is considered **legacy** but still found in older environments.

### NT4-Style Domain Configuration

```ini
[global]
   workgroup = OLDOMAIN
   server string = %h PDC (Legacy)
   netbios name = PDC01
   security = user
   passdb backend = tdbsam

   # PDC-specific options
   domain logons = yes
   domain master = yes
   preferred master = yes
   os level = 65              # Higher than any Windows machine
   local master = yes

   # Logon scripts
   logon script = logon.bat
   logon path = \\%N\%U\profile
   logon drive = H:
   logon home = \\%N\%U

   # WINS
   wins support = yes

   # Roaming profiles
   logon path = \\%N\profiles\%U
   profile acls = yes

[netlogon]
   comment = Network Logon Service
   path = /var/lib/samba/netlogon
   browseable = no
   read only = no
   guest ok = yes

[profiles]
   comment = Roaming Profiles
   path = /var/lib/samba/profiles
   read only = no
   profile acls = yes
   browseable = no
   create mask = 0600
   directory mask = 0700
```

**Important:** NT4-style domains are deprecated. Use security = ADS (domain member) or the samba-ad-dc for modern deployments.

---

## 🔍 Section 6: Samba as Active Directory Domain Controller

Samba 4.x can act as a full Active Directory Domain Controller — including Kerberos KDC, DNS server, LDAP, and Group Policy processing.

### Architecture of samba-ad-dc

```
samba-ad-dc replaces these Windows Server roles:
  ┌────────────────────────────────────┐
  │ Active Directory Domain Services   │
  │  └─ LDAP (port 389/636)           │
  │  └─ Kerberos KDC (port 88)        │
  │  └─ DNS (port 53)                 │
  │  └─ SMB/CIFS (port 445)           │
  │  └─ Global Catalog (port 3268)    │
  │  └─ NTP (port 123)                │
  └────────────────────────────────────┘
```

### Provisioning a New AD Domain

```bash
# 1. Install samba-ad-dc package
sudo apt install samba smbclient winbind bind9 bind9utils dnsutils
# On Ubuntu: samba-ad-dc is part of the samba package

# 2. Stop conflicting services (bind9 may conflict with samba's internal DNS)
sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved

# 3. Remove existing smb.conf (provisioning creates a new one)
sudo mv /etc/samba/smb.conf /etc/samba/smb.conf.backup

# 4. Provision the domain
sudo samba-tool domain provision \
   --use-rfc2307 \
   --interactive
# Realm [AD.COMPANY.COM]: AD.COMPANY.COM
# Domain [AD]: AD
# Server Role (dc, member, standalone) [dc]: dc
# DNS backend (SAMBA_INTERNAL, BIND9_FLATFILE, BIND9_DLZ, NONE) [SAMBA_INTERNAL]: SAMBA_INTERNAL
# DNS forwarder (IP address, or 'none'): 8.8.8.8
# Administrator password: ********
# Retype password: ********

# 5. The provisioned files
ls -la /var/lib/samba/private/
# keytab, sam.ldb, sam.ldb.d/, secrets.tdb, *.ldb

# 6. Enable and start the AD DC
sudo systemctl mask smbd nmbd winbind     # These conflict with samba-ad-dc
sudo systemctl enable --now samba-ad-dc

# 7. Verify
sudo samba-tool domain level show
# Domain functional level: 2008_R2
# Forest functional level: 2008_R2

sudo samba-tool domain info 127.0.0.1
```

### smb.conf Created by Provisioning

```ini
# /var/lib/samba/private/smb.conf (or /etc/samba/smb.conf after provision)
[global]
   netbios name = DC01
   realm = AD.COMPANY.COM
   server role = active directory domain controller
   workgroup = AD
   server services = s3fs, rpc, nbt, wrepl, ldap, cldap, kdc, drepl, winbindd, ntp_signd, kcc, dnsupdate
   server signing = mandatory
   dns forwarder = 8.8.8.8
   idmap_ldb:use rfc2307 = yes
```

### Adding Users and Groups

```bash
# Add a user
sudo samba-tool user create jdoe
# New password: ********
# Retype password: ********
# User 'jdoe' created successfully

# Add a group
sudo samba-tool group add "Engineering"

# Add user to group
sudo samba-tool group addmembers "Engineering" jdoe

# Set user attributes (RFC2307 for Unix integration)
sudo samba-tool user edit jdoe
# Set: uidNumber, gidNumber, unixHomeDirectory, loginShell

# List all users
sudo samba-tool user list

# List all groups
sudo samba-tool group list
```

### DNS Management

```bash
# Add DNS record
sudo samba-tool dns add 127.0.0.1 ad.company.com fileserver A 192.168.1.50

# Query DNS
sudo samba-tool dns query 127.0.0.1 ad.company.com @ ALL

# Add reverse lookup zone
sudo samba-tool dns zonelist 127.0.0.1
```

### Bind9 DLZ (Dynamic Loadable Zone) Setup

For production AD deployments, use Bind9 DLZ instead of the internal DNS:

```bash
# 1. Install Bind9 with DLZ support
sudo apt install bind9

# 2. Configure named.conf to load Samba's DLZ module
sudo tee -a /etc/bind/named.conf.local << 'EOF'
dlz "AD.COMPANY.COM" {
   database "dlopen /usr/lib/x86_64-linux-gnu/samba/bind9/dlz_bind9_11.so";
};
EOF

# 3. Provision with BIND9_DLZ backend
sudo samba-tool domain provision \
   --use-rfc2307 \
   --dns-backend=BIND9_DLZ \
   --realm=AD.COMPANY.COM \
   --domain=AD \
   --adminpass='P@ssw0rd!'
```

---

## 🔍 Section 7: Linux Mounting CIFS Shares

Mounting Windows or Samba shares on Linux uses the `cifs` kernel client.

### Basic Mount

```bash
# Install cifs-utils
sudo apt install cifs-utils

# Mount a share
sudo mount -t cifs //192.168.1.100/shared /mnt/smb \
   -o username=alice,password=secret

# Mount with domain
sudo mount -t cifs //dc01/shared /mnt/smb \
   -o username=alice,password=secret,domain=AD
```

### Using a Credentials File

Storing passwords in `mount` commands or `/etc/fstab` is a security risk. Use a credentials file:

```bash
# Create a credentials file
sudo tee /etc/samba/credentials/shared.cred << 'EOF'
username=alice
password=super-secret-password
domain=WORKGROUP
EOF

sudo chmod 600 /etc/samba/credentials/shared.cred

# Mount with credentials file
sudo mount -t cifs //192.168.1.100/shared /mnt/smb \
   -o credentials=/etc/samba/credentials/shared.cred,uid=1000,gid=1000
```

### /etc/fstab Entry

```bash
# /etc/fstab entry for persistent mount
# //server/share  /mount/point  cifs  options  0  0

//192.168.1.100/shared  /mnt/smb  cifs  credentials=/etc/samba/credentials/shared.cred,uid=1000,gid=1000,iocharset=utf8,noexec  0  0
```

### Mount Options Reference

```bash
-o username=USER            # SMB username
-o password=PASS            # SMB password (avoid, use credentials file)
-o domain=DOMAIN            # Authentication domain
-o credentials=FILE         # File containing username/password/domain

-o uid=1000                 # Local owner of mounted files
-o gid=1000                 # Local group of mounted files
-o dir_mode=0755            # Directory permissions
-o file_mode=0644           # File permissions
-o fmask=0137               # File permission mask (subtractive)
-o dmask=0027               # Directory permission mask
-o forceuid                 # Force file owner to uid even if server says otherwise
-o forcegid                 # Force file group to gid

-o iocharset=utf8           # Character set for file names
-o codepage=cp850           # Server codepage (DOS/Windows)

-o noserverino              # Don't use inode numbers from server
-o serverino                # Use inode numbers from server (default)

-o sec=ntlmssp              # Security mode: ntlm, ntlmv2, ntlmssp, krb5
-o vers=3.0                 # SMB protocol version (1.0, 2.0, 2.1, 3.0, 3.1.1)
-o cache=none               # Cache mode: none, strict, loose

-o nobrl                    # Don't send byte range locks to server
-o nostrictsync             # Don't flush on fsync (better performance)

-o multichannel             # SMB3 multichannel (kernel 5.3+)
-o reconn                   # Reconnect if connection drops
-o echo_interval=30         # Keepalive interval in seconds
```

### Multichannel Support

SMB3 multichannel allows using multiple network paths for increased throughput:

```bash
# Mount with multichannel enabled
sudo mount -t cifs //192.168.1.100/shared /mnt/smb \
   -o vers=3.0,multichannel,credentials=/etc/samba/credentials/shared.cred

# Check if multichannel is active
cat /proc/fs/cifs/DebugData | grep -A2 "Multichannel"
```

### Checking Mounted CIFS Shares

```bash
# Standard mount check
mount -t cifs

# Detailed mount info
findmnt -t cifs

# CIFS stats
cat /proc/fs/cifs/Stats

# Per-mount stats
cat /proc/fs/cifs/DebugData
```

---

## 🔍 Section 8: smbclient — The Interactive SMB Client

smbclient is an FTP-like tool for accessing SMB shares from the command line.

### Listing Shares

```bash
# List all shares on a server (anonymous)
smbclient -L //192.168.1.100 -N

# List shares with credentials
smbclient -L //fileserver -U alice%password

# List shares on a domain member
smbclient -L //dc01 -U administrator -W AD
```

### Interactive Sessions

```bash
# Connect to a share
smbclient //192.168.1.100/shared -U alice

# smbclient: \> prompt
# Available commands:
#   ls             — list files
#   cd DIR         — change directory
#   get FILE       — download file
#   put FILE       — upload file
#   mget PATTERN   — multi-get (with prompt)
#   mput PATTERN   — multi-put (with prompt)
#   rm FILE        — delete file
#   mkdir DIR      — create directory
#   rmdir DIR      — remove directory
#   prompt         — toggle interactive prompts
#   recurse        — toggle recursion for mget/mput
#   tar            — tar operations
#   chmod PERMS FILE — change permissions (if supported)
#   chown USER FILE  — change owner (if supported)
#   du             — directory usage
#   lcd LOCALDIR   — change local directory
#   ! COMMAND      — run local command
#   help           — list commands
#   exit / quit    — disconnect
```

### smbclient Scripting

```bash
# Use smbclient in scripts with -c
smbclient //server/share -U alice%password -c '
   ls
   cd data
   get report.pdf
   put backup.tar.gz
   rm temp.txt
   exit
'
```

### smbclient with Kerberos

```bash
# Get a Kerberos ticket first
kinit alice@AD.COMPANY.COM

# Use the ticket (-k for Kerberos)
smbclient -k //dc01/netlogon -c ls

# Specify the service principal name
smbclient -k //dc01/netlogon -c ls --use-kerberos=required
```

---

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

---

## 🔍 Section 10: Winbind — Integrating Windows Users into Linux

Winbind is the component that makes Windows users and groups appear as Linux users and groups.

### How Winbind Works

```
Windows Domain Controller (Active Directory)
        │
        │ LDAP/Kerberos queries
        ▼
   winbindd ─── listens on Unix sockets (nss_winbind, pam_winbind)
        │
        ├── nss_winbind → /etc/nsswitch.conf
        │   └─ getent passwd shows domain users
        │   └─ getent group shows domain groups
        │
        └── pam_winbind → /etc/pam.d/
            └─ Authenticate Linux logins against AD
            └─ Create home directories on first login (pam_mkhomedir)
```

### nsswitch.conf Integration

```bash
# /etc/nsswitch.conf
passwd:         files systemd winbind
group:          files systemd winbind
shadow:         files winbind

# After this, domain users appear in Linux user database:
getent passwd | grep AD
# AD\administrator:*:20000:20000:Administrator:/home/AD/administrator:/bin/bash
# AD\jdoe:*:20001:20001:John Doe:/home/AD/jdoe:/bin/bash

getent group | grep AD
# AD\domain users:*:20000:
# AD\domain admins:*:20001:
# AD\engineering:*:20005:
```

### wbinfo Commands

```bash
wbinfo -p                          # Ping winbindd
wbinfo -t                          # Check domain trust

wbinfo -u                          # List domain users
wbinfo -g                          # List domain groups

wbinfo -i jdoe                     # Get user info (like id command)
wbinfo -n jdoe                     # Get SID for a username
wbinfo -S S-1-5-21-...-500        # Get UID from SID
wbinfo -s S-1-5-21-...-500        # Get username from SID

wbinfo --name-to-sid jdoe          # Get SID (verbose)
wbinfo --sid-to-fullname S-...     # Get full name from SID

wbinfo --online-status             # Check if winbind is online
wbinfo --domain-info AD            # Show domain information
```

### ID Mapping Backends

The `idmap` configuration determines how Windows SIDs map to Linux UIDs/GIDs.

```ini
# RID backend (simplest, deterministic)
# UID = 20000 + RID
# RID = last part of SID
# Example: S-1-5-21-1234-5678-9012-500 → RID=500 → UID=20500
[global]
   idmap config AD : backend = rid
   idmap config AD : range = 20000-29999
   idmap config * : backend = tdb
   idmap config * : range = 10000-19999

# AD backend (reads uidNumber/gidNumber from AD)
# Requires RFC2307 attributes set on AD users/groups
[global]
   idmap config AD : backend = ad
   idmap config AD : range = 20000-29999
   idmap config AD : schema_mode = rfc2307
   idmap config * : backend = tdb
   idmap config * : range = 10000-19999

# LDAP backend (stores mapping in LDAP)
[global]
   idmap config AD : backend = ldap
   idmap config AD : ldap_url = ldap://ldap.company.com
   idmap config AD : ldap_base_dn = ou=idmap,dc=company,dc=com
   idmap config AD : range = 20000-29999
```

### PAM Integration for Linux Login

```bash
# Allow domain users to SSH into the Linux server
sudo tee /etc/pam.d/common-auth << 'EOF'
auth    required    pam_env.so
auth    sufficient  pam_unix.so
auth    sufficient  pam_winbind.so
auth    required    pam_deny.so
EOF

# Auto-create home directories
sudo tee /etc/pam.d/common-session << 'EOF'
session required    pam_unix.so
session required    pam_mkhomedir.so umask=0022 skel=/etc/skel
EOF
```

---

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

## 🔍 Section 12: Performance Tuning

### Socket Options

```ini
[global]
   # TCP socket tuning
   socket options = TCP_NODELAY IPTOS_LOWDELAY SO_KEEPALIVE
   # TCP_NODELAY     — Disable Nagle's algorithm (send small packets immediately)
   # IPTOS_LOWDELAY  — Minimize delay (for interactive traffic)
   # SO_KEEPALIVE    — Detect dead connections

   # For high-throughput (bulk transfers)
   socket options = TCP_NODELAY IPTOS_THROUGHPUT SO_RCVBUF=131072 SO_SNDBUF=131072
```

### Read/Write Size Tuning

```ini
[global]
   # Larger buffers = better throughput for large files
   read raw = yes               # Enable SMB read raw (large reads)
   write raw = yes              # Enable SMB write raw (large writes)

   # Read size limits
   min receivefile size = 16384 # Minimum size for sendfile path
   strict allocate = no         # Don't pre-allocate space (faster writes)
   use mmap = yes               # Use mmap for file I/O (if available)

   # Write cache
   write cache size = 262144    # Write cache per file (256KB)
```

### SMB3 Multichannel Configuration

```ini
[global]
   # Enable multichannel (SMB3)
   server multi channel support = yes

   # Optional: bind to specific interfaces
   interfaces = eth0 eth1 10.0.0.0/24
   bind interfaces only = yes
```

### Other Performance Settings

```ini
[global]
   # Number of smbd processes pre-forked
   max smbd processes = 100

   # Dead client detection
   deadtime = 15               # Disconnect idle connections after 15 min

   # Large directory optimization
   getwd cache = yes           # Cache current working directory
   directory name cache size = 100

   # Async I/O
   aio read size = 4096        # Async read for files > 4KB
   aio write size = 4096       # Async write for files > 4KB
   aio max threads = 100       # Max async I/O threads
```

### Benchmarking Samba Performance

```bash
# 1. Using smbclient with tar
time smbclient //server/share -U user%pass -c 'tar c .' > /dev/null

# 2. Using dd over CIFS mount
mount -t cifs //server/share /mnt/test -o ...
time dd if=/dev/zero of=/mnt/test/testfile bs=1M count=1000

# 3. Using iperf3 for network baseline
iperf3 -c 192.168.1.100

# 4. Check SMB version in use
smbstatus | grep -E "SMB|protocol"
```

---

## 💻 PRACTICE SECTION — 15 Hands-On Exercises

---

### 📘 Level 1 Practices: Samba Installation and Basic Shares

Install Samba, explore the package structure, validate configuration with testparm, and create your first standalone share.

### ✅ Practice 1: Install Samba and Explore the Package

```bash
mkdir -p ~/linux-course/part29
cd ~/linux-course/part29

# Install Samba
sudo apt update
sudo apt install -y samba smbclient cifs-utils

# Verify installation
dpkg -l | grep samba
smbd --version
nmbd --version

# List all Samba binaries
dpkg -L samba-common | grep bin
ls /usr/sbin/smb*

# Check which services are available
systemctl list-unit-files | grep -i samba
systemctl list-unit-files | grep nmb
systemctl list-unit-files | grep winbind
```

---

### ✅ Practice 2: Explore Default smb.conf and testparm

```bash
cd ~/linux-course/part29

# Check the default configuration
cat /etc/samba/smb.conf

# Count lines, sections
grep '^\[.*\]$' /etc/samba/smb.conf
echo "---"
grep -c '^\[.*\]$' /etc/samba/smb.conf
echo "sections found"

# Validate with testparm
testparm -s 2>&1

# Output only the global parameters
testparm -s --parameter-name "workgroup" 2>/dev/null
testparm -s --parameter-name "server string" 2>/dev/null
testparm -s --parameter-name "security" 2>/dev/null

# Save the full verbose output
testparm -v 2>/dev/null > default_samba_params.txt
head -50 default_samba_params.txt
```

---

### ✅ Practice 3: Create a Simple Standalone Share

---

### 📘 Level 2 Practices: Client Tools, Mounting, Monitoring, and Domain Operations

Connect with smbclient, mount CIFS shares, set up user-level security, monitor connections with smbstatus, configure logging, and test SMB protocol versions.

```bash
cd ~/linux-course/part29

# 1. Create a directory for the share
sudo mkdir -p /srv/samba/labshare

# 2. Create some test files
echo "Welcome to the Samba lab share" | sudo tee /srv/samba/labshare/README.txt
sudo touch /srv/samba/labshare/{document1.txt,datafile.csv,report.pdf}

# 3. Set permissions
sudo chown -R nobody:nogroup /srv/samba/labshare
sudo chmod -R 0775 /srv/samba/labshare

# 4. Back up and create new smb.conf
sudo cp /etc/samba/smb.conf /etc/samba/smb.conf.backup

sudo tee /etc/samba/smb.conf << 'EOF'
[global]
   workgroup = WORKGROUP
   server string = Lab Samba Server
   netbios name = LABSERVER
   security = user
   map to guest = Bad User
   dns proxy = no
   log file = /var/log/samba/log.%m
   max log size = 1000

[labshare]
   comment = Lab Practice Share
   path = /srv/samba/labshare
   read only = no
   guest ok = yes
   browseable = yes
   create mask = 0644
   directory mask = 0755
EOF

# 5. Validate and restart
testparm -s
sudo systemctl restart smbd nmbd
sudo systemctl status smbd --no-pager -l
```

---

### ✅ Practice 4: Connect to Your Share with smbclient

```bash
cd ~/linux-course/part29

# 1. List shares on your own server
smbclient -L //127.0.0.1 -N -p 445

# 2. Connect interactively
smbclient //127.0.0.1/labshare -N

# Inside smbclient:
#   ls
#   get README.txt
#   put /etc/hostname hostname.txt
#   ls
#   exit

# 3. Scripted smbclient
smbclient //127.0.0.1/labshare -N -c '
   ls
   get README.txt
   put /etc/hostname labhostname.txt
   ls
   exit
'

# 4. Verify downloaded files
cat README.txt
cat labhostname.txt 2>/dev/null || echo "Check local directory"
```

---

### ✅ Practice 5: Set Up User-Level Security

```bash
cd ~/linux-course/part29

# 1. Create local users
sudo useradd -m -s /usr/sbin/nologin labuser1
sudo useradd -m -s /usr/sbin/nologin labuser2

# 2. Set SMB passwords
echo -e "Pass1234\nPass1234" | sudo smbpasswd -a labuser1 -s
echo -e "Pass5678\nPass5678" | sudo smbpasswd -a labuser2 -s

# 3. Verify users in pdbedit
sudo pdbedit -L

# 4. Create a secure share
sudo mkdir -p /srv/samba/secure
echo "Confidential data" | sudo tee /srv/samba/secure/secret.txt

# 5. Update smb.conf
sudo tee -a /etc/samba/smb.conf << 'EOF'

[secure]
   comment = Secure Share (Authorized Users Only)
   path = /srv/samba/secure
   valid users = labuser1
   read only = no
   browseable = no
   create mask = 0600
   directory mask = 0700
EOF

testparm -s

# 6. Set file system permissions
sudo chown -R root:labuser1 /srv/samba/secure
sudo chmod 2770 /srv/samba/secure

sudo systemctl restart smbd

# 7. Test access
echo "--- Testing labuser1 (should succeed) ---"
smbclient //127.0.0.1/secure -U labuser1%Pass1234 -c 'ls; get secret.txt; exit'

echo "--- Testing labuser2 (should fail) ---"
smbclient //127.0.0.1/secure -U labuser2%Pass5678 -c 'ls; exit' 2>&1
```

---

### ✅ Practice 6: Mount a CIFS Share on Linux

```bash
cd ~/linux-course/part29

# 1. Create mount point
sudo mkdir -p /mnt/labshare

# 2. Create a credentials file
sudo mkdir -p /etc/samba/credentials
sudo tee /etc/samba/credentials/labuser1.cred << 'EOF'
username=labuser1
password=Pass1234
domain=WORKGROUP
EOF

sudo chmod 600 /etc/samba/credentials/labuser1.cred

# 3. Mount the share
sudo mount -t cifs //127.0.0.1/secure /mnt/labshare \
   -o credentials=/etc/samba/credentials/labuser1.cred,uid=$(id -u),gid=$(id -g),iocharset=utf8,vers=3.0

# 4. Verify
mount -t cifs
df -h /mnt/labshare
ls -la /mnt/labshare

# 5. Write a file through the mount
echo "Written via CIFS mount at $(date)" > /mnt/labshare/test_write.txt
cat /mnt/labshare/test_write.txt

# 6. See it via smbclient
smbclient //127.0.0.1/secure -U labuser1%Pass1234 -c 'ls; exit'

# 7. Unmount
sudo umount /mnt/labshare
```

---

### ✅ Practice 7: Explore smbstatus and Connection Monitoring

```bash
cd ~/linux-course/part29

# 1. Open two terminals, or use background:
# Terminal 1: Keep a connection open
smbclient //127.0.0.1/labshare -N -c 'sleep 30; exit' &
SMBPID=$!

# 2. Check smbstatus while connected
sleep 2
smbstatus
smbstatus -p
smbstatus -S

# 3. Note the PID
echo "smbclient PID: $SMBPID"
ps aux | grep smb[c]lient

# 4. Find the smbd child handling it
ps aux | grep smbd

# 5. Close the connection
kill $SMBPID 2>/dev/null
sleep 1
smbstatus

# 6. Test lock display
# Create a lock scenario:
(echo "lock"; sleep 10; echo "release") | smbclient //127.0.0.1/labshare -N -c 'open README.txt; sleep 10; close; exit' &
sleep 3
smbstatus -L

wait
```

---

### ✅ Practice 8: Create Multiple Shares with Permission Masks

```bash
cd ~/linux-course/part29

# 1. Create department-style shares
sudo mkdir -p /srv/samba/{dept_a,dept_b,archive}
echo "Department A data" | sudo tee /srv/samba/dept_a/readme.txt
echo "Department B data" | sudo tee /srv/samba/dept_b/readme.txt
echo "Archive data" | sudo tee /srv/samba/archive/readme.txt

# 2. Create groups and users
sudo groupadd dept_a
sudo groupadd dept_b
sudo usermod -aG dept_a labuser1
sudo usermod -aG dept_b labuser2

# 3. Set filesystem permissions
sudo chown root:dept_a /srv/samba/dept_a
sudo chmod 2770 /srv/samba/dept_a
sudo chown root:dept_b /srv/samba/dept_b
sudo chmod 2770 /srv/samba/dept_b
sudo chown root:root /srv/samba/archive
sudo chmod 2775 /srv/samba/archive

# 4. Add share definitions
sudo tee /etc/samba/shares.conf << 'EOF'
[dept_a]
   comment = Department A
   path = /srv/samba/dept_a
   valid users = @dept_a
   read only = no
   create mask = 0660
   directory mask = 0770
   browseable = yes

[dept_b]
   comment = Department B
   path = /srv/samba/dept_b
   valid users = @dept_b
   read only = no
   create mask = 0660
   directory mask = 0770
   browseable = yes

[archive]
   comment = Shared Archive
   path = /srv/samba/archive
   valid users = @dept_a, @dept_b
   read only = yes
   browseable = yes
EOF

echo "include = /etc/samba/shares.conf" | sudo tee -a /etc/samba/smb.conf

testparm -s
sudo systemctl restart smbd

# 5. Test access
echo "--- Department A access ---"
smbclient //127.0.0.1/dept_a -U labuser1%Pass1234 -c 'ls; put /etc/hostname host_from_a.txt; ls; exit'

echo "--- Department B access (should fail for A) ---"
smbclient //127.0.0.1/dept_b -U labuser1%Pass1234 -c 'ls; exit' 2>&1

echo "--- Archive (read-only) ---"
smbclient //127.0.0.1/archive -U labuser1%Pass1234 -c 'ls; exit'
```

---

### ✅ Practice 9: Configure Samba Logging and Debugging

```bash
cd ~/linux-course/part29

# 1. Set log level for debugging
sudo tee /etc/samba/smb.conf.d/debug.conf << 'EOF'
[global]
   log level = 3 auth:5
   log file = /var/log/samba/log.%m
   max log size = 5000
EOF

echo "include = /etc/samba/smb.conf.d/debug.conf" | sudo tee -a /etc/samba/smb.conf

sudo systemctl restart smbd

# 2. Generate some log activity
smbclient //127.0.0.1/labshare -N -c 'ls; get README.txt; exit'

# 3. Examine logs
sudo ls -la /var/log/samba/
sudo cat /var/log/samba/log.127.0.0.1

# 4. Set logging back to normal
sudo sed -i 's/log level = 3 auth:5/log level = 1/' /etc/samba/smb.conf.d/debug.conf
sudo systemctl restart smbd
```

---

### ✅ Practice 10: SMB Protocol Version Testing

---

### 📘 Level 3 Practices: Advanced Features, Security, and Performance

Test file locking and oplocks, enable SMB encryption, benchmark Samba transfers, and build a mixed Linux/Windows file server integration project.

```bash
cd ~/linux-course/part29

# 1. Force SMB2 and test
sudo tee /etc/samba/smb.conf.d/protocol.conf << 'EOF'
[global]
   server min protocol = SMB2_02
   server max protocol = SMB3_11
   disable netbios = yes
   smb ports = 445
EOF

# include this in main config (check if not already there)
grep -q "protocol.conf" /etc/samba/smb.conf || \
   echo "include = /etc/samba/smb.conf.d/protocol.conf" | sudo tee -a /etc/samba/smb.conf

sudo systemctl restart smbd nmbd

# 2. Try SMB1 (should fail)
echo "--- Attempt SMB1 connection (should fail) ---"
smbclient -L //127.0.0.1 -m NT1 -N 2>&1 || echo "SMB1 correctly rejected"

# 3. Try modern protocols (should work)
echo "--- SMB2.02 ---"
smbclient -L //127.0.0.1 -m SMB2_02 -N 2>&1 | head -5

echo "--- SMB3.11 ---"
smbclient -L //127.0.0.1 -m SMB3_11 -N 2>&1 | head -5

# 4. Verify NetBIOS disabled (port 139)
ss -tlnp | grep -E ':139|:445'
echo "Port 139 should not be listening (NetBIOS disabled)"
```

---

### ✅ Practice 11: smbclient Advanced Operations

```bash
cd ~/linux-course/part29

# 1. Create a local test directory with files
mkdir -p smbclient_test
dd if=/dev/urandom bs=1M count=10 of=smbclient_test/largefile.bin 2>/dev/null
echo "small file content" > smbclient_test/small.txt
echo "another file" > smbclient_test/another.txt

# 2. Upload multiple files with mput
smbclient //127.0.0.1/labshare -N -c "
   lcd smbclient_test
   prompt OFF
   mput *
   ls
   exit
"

# 3. Download with mget
mkdir -p smbclient_download
smbclient //127.0.0.1/labshare -N -c "
   lcd smbclient_download
   prompt OFF
   mget *
   ls
   exit
"

# 4. Verify download
ls -la smbclient_download/

# 5. Use tar over smbclient
smbclient //127.0.0.1/labshare -N -c '
   tar c labshare_backup.tar
   ls *.tar
   exit
'

# 6. Recursive directory operations
smbclient //127.0.0.1/labshare -N -c '
   mkdir subdir1
   cd subdir1
   mkdir subdir2
   cd subdir2
   put /etc/hostname nested_test.txt
   recurse ON
   ls
   exit
'
```

---

### ✅ Practice 12: Test File Locking and Oplocks

```bash
cd ~/linux-course/part29

# 1. Configure oplocks on the share
sudo tee /etc/samba/smb.conf.d/locks.conf << 'EOF'
[global]
   kernel oplocks = yes
   lock spin count = 10
   lock spin time = 100

[labshare]
   oplocks = yes
   level2 oplocks = yes
   blocking locks = yes
EOF

grep -q "locks.conf" /etc/samba/smb.conf || \
   echo "include = /etc/samba/smb.conf.d/locks.conf" | sudo tee -a /etc/samba/smb.conf

sudo systemctl restart smbd

# 2. Create a test file
echo "Lock test content" > /tmp/lock_test.txt
smbclient //127.0.0.1/labshare -N -c "put /tmp/lock_test.txt lock_test.txt; exit"

# 3. Open in one session with a hold
smbclient //127.0.0.1/labshare -N -c '
   open lock_test.txt
   sleep 15
   close
   exit
' &

sleep 3

# 4. Try to open the same file from another session
echo "--- Second session attempting to open locked file ---"
smbclient //127.0.0.1/labshare -N -c '
   open lock_test.txt
   ls
   exit
' &

sleep 5
smbstatus -L

wait
```

---

### ✅ Practice 13: Test SMB Encryption

```bash
cd ~/linux-course/part29

# 1. Enable encryption on the labshare
sudo tee /etc/samba/smb.conf.d/encrypt.conf << 'EOF'
[global]
   server smb encrypt = desired

[labshare]
   smb encrypt = required
EOF

grep -q "encrypt.conf" /etc/samba/smb.conf || \
   echo "include = /etc/samba/smb.conf.d/encrypt.conf" | sudo tee -a /etc/samba/smb.conf

testparm -s
sudo systemctl restart smbd

# 2. Connect and check encryption status
smbclient //127.0.0.1/labshare -N -c 'ls; exit'

# 3. Check smbstatus for encryption column
smbstatus | grep -i encrypt

# 4. Mount with encryption requirement
sudo mount -t cifs //127.0.0.1/labshare /mnt/labshare \
   -o guest,vers=3.0,seal
# seal = require encryption at SMB3 level

mount -t cifs
sudo umount /mnt/labshare
```

---

### ✅ Practice 14: Benchmark Samba Transfers

```bash
cd ~/linux-course/part29

# 1. Create a large test file
dd if=/dev/zero of=/tmp/benchmark_test.dat bs=1M count=100 2>/dev/null

# 2. Upload timing
echo "--- Upload benchmark ---"
time smbclient //127.0.0.1/labshare -N -c "put /tmp/benchmark_test.dat benchmark.dat; exit"

# 3. Download timing (different file name to avoid cache)
smbclient //127.0.0.1/labshare -N -c "put /tmp/benchmark_test.dat download_test.dat; exit"
echo "--- Download benchmark ---"
time smbclient //127.0.0.1/labshare -N -c "get download_test.dat /dev/null; exit"

# 4. Compare SMB versions
echo "--- SMB2.02 upload ---"
time smbclient //127.0.0.1/labshare -N -m SMB2_02 -c "put /tmp/benchmark_test.dat smb2_bench.dat; exit"

echo "--- SMB3.11 upload ---"
time smbclient //127.0.0.1/labshare -N -m SMB3_11 -c "put /tmp/benchmark_test.dat smb3_bench.dat; exit"

# 5. Clean up test files
smbclient //127.0.0.1/labshare -N -c '
   rm benchmark.dat
   rm download_test.dat
   rm smb2_bench.dat
   rm smb3_bench.dat
   ls
   exit
'

rm -f /tmp/benchmark_test.dat
```

---

### ✅ Practice 15: Real-World Integration — Mixed Linux/Windows File Server

```bash
cd ~/linux-course/part29

# Build a complete, production-style file server configuration

# 1. Create directory structure
sudo mkdir -p /srv/samba/{profiles,home,groups/{sales,engineering,exec},public}
sudo mkdir -p /srv/samba/groups/sales/{invoices,reports,archive}
sudo mkdir -p /srv/samba/groups/engineering/{designs,specs,builds}
sudo mkdir -p /srv/samba/exec/confidential
sudo mkdir -p /srv/samba/public/software
sudo mkdir -p /srv/samba/profiles/{sales_vp,engineer_lead}

# 2. Create groups and users
sudo groupadd --gid 5000 sales
sudo groupadd --gid 5001 engineering
sudo groupadd --gid 5002 execs

for user in alice bob charlie dave eve; do
    sudo useradd -m -s /usr/sbin/nologin -g users -G users "$user"
    echo -e "Pass1234\nPass1234" | sudo smbpasswd -a "$user" -s
done

sudo usermod -aG sales alice
sudo usermod -aG sales bob
sudo usermod -aG engineering charlie
sudo usermod -aG engineering dave
sudo usermod -aG execs eve
sudo usermod -aG sales eve  # Exec can see sales too

# 3. Set filesystem permissions
sudo chown root:sales /srv/samba/groups/sales
sudo chmod 2770 /srv/samba/groups/sales

sudo chown root:engineering /srv/samba/groups/engineering
sudo chmod 2770 /srv/samba/groups/engineering

sudo chown root:execs /srv/samba/exec
sudo chmod 2770 /srv/samba/exec

sudo chown root:users /srv/samba/public
sudo chmod 2775 /srv/samba/public

sudo chown eve:execs /srv/samba/exec/confidential
sudo chmod 2770 /srv/samba/exec/confidential

# 4. Create sample files
echo "Q4 Financial Report (Draft)" | sudo tee /srv/samba/groups/sales/reports/q4_draft.txt
echo "Server Design v2.1" | sudo tee /srv/samba/groups/engineering/designs/server_v2.txt
echo "Board Meeting Minutes" | sudo tee /srv/samba/exec/confidential/board_minutes.txt
echo "Public Software Release" | sudo tee /srv/samba/public/software/readme.txt

# 5. Write the production config
sudo tee /etc/samba/smb.conf << 'EOF'
[global]
   workgroup = COMPANY
   server string = Production File Server
   netbios name = FILESRV
   security = user
   map to guest = Never
   dns proxy = no

   # Performance
   socket options = TCP_NODELAY IPTOS_LOWDELAY SO_KEEPALIVE
   read raw = yes
   write raw = yes
   strict allocate = no
   use mmap = yes
   getwd cache = yes

   # Security
   server min protocol = SMB2_10
   server smb encrypt = desired
   client signing = required
   disable netbios = yes
   smb ports = 445

   # Logging
   log level = 1
   log file = /var/log/samba/log.%m
   max log size = 5000

[homes]
   comment = Home Directories
   browseable = no
   read only = no
   create mask = 0700
   directory mask = 0700
   valid users = %S

[sales]
   comment = Sales Department
   path = /srv/samba/groups/sales
   valid users = @sales
   read only = no
   create mask = 0660
   directory mask = 0770
   browseable = yes
   veto files = /Thumbs.db/.DS_Store/
   hide unreadable = yes

[engineering]
   comment = Engineering Department
   path = /srv/samba/groups/engineering
   valid users = @engineering
   read only = no
   create mask = 0664
   directory mask = 0775
   browseable = yes
   veto files = /Thumbs.db/.DS_Store/

[exec]
   comment = Executive
   path = /srv/samba/exec
   valid users = @execs
   read only = no
   create mask = 0660
   directory mask = 0770
   browseable = no

[public]
   comment = Company Public Files
   path = /srv/samba/public
   guest ok = yes
   read only = yes
   browseable = yes
   create mask = 0644
   directory mask = 0755
EOF

# 6. Validate
testparm -s

# 7. Restart
sudo systemctl restart smbd

# 8. Test all shares
echo "=== Testing All Shares ==="
echo ""

echo "--- Sales (alice) ---"
smbclient //127.0.0.1/sales -U alice%Pass1234 -c 'ls; cd reports; ls; exit'

echo "--- Engineering (charlie) ---"
smbclient //127.0.0.1/engineering -U charlie%Pass1234 -c 'ls; cd designs; ls; exit'

echo "--- Engineering for sales user (should fail) ---"
smbclient //127.0.0.1/engineering -U alice%Pass1234 -c 'ls; exit' 2>&1

echo "--- Exec (eve) ---"
smbclient //127.0.0.1/exec -U eve%Pass1234 -c 'ls; cd confidential; ls; get board_minutes.txt; exit'

echo "--- Public (anonymous) ---"
smbclient //127.0.0.1/public -N -c 'ls; cd software; ls; exit'

# 9. Check smbstatus
echo ""
echo "=== Active Connections ==="
smbstatus

# 10. Create a summary report
{
    echo "============================================"
    echo "  SAMBA INTEGRATION PRACTICE REPORT"
    echo "  $(date)"
    echo "============================================"
    echo ""
    echo "Server: $(hostname)"
    echo "Samba version: $(smbd --version 2>&1)"
    echo ""
    echo "Shares configured:"
    smbclient -L //127.0.0.1 -U alice%Pass1234 2>/dev/null | grep -E '^\t' | grep -v '^$'
    echo ""
    echo "Users with SMB access:"
    sudo pdbedit -L 2>/dev/null
    echo ""
    echo "Active connections:"
    smbstatus -p 2>/dev/null
    echo ""
    echo "Check: testparm validation"
    testparm -s 2>&1 | grep -E "Loaded|Processing"
    echo "============================================"
} | tee integration_report.txt

echo ""
echo "Practice 15 complete — integration report saved to integration_report.txt"
```

---

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

---

## 📋 Summary — Complete Command Reference for Part 29

### ⭐ Level 1 Commands: Basic Samba Operations

**Service Management**

| Command | Action |
|---------|--------|
| `sudo systemctl start smbd` | Start Samba file/print services |
| `sudo systemctl stop smbd` | Stop Samba |
| `sudo systemctl restart smbd` | Restart Samba |
| `sudo systemctl enable smbd` | Enable at boot |
| `sudo systemctl start nmbd` | Start NetBIOS name service |

**Configuration Validation**

| Command | Action |
|---------|--------|
| `testparm` | Validate smb.conf syntax |
| `testparm -v` | Show all parameters with defaults |

### ⭐ Level 2 Commands: Shares, Clients, Monitoring, and Winbind

**User and Share Management**

| Command | Action |
|---------|--------|
| `sudo smbpasswd -a USER` | Add SMB user |
| `sudo smbpasswd -x USER` | Delete SMB user |
| `sudo smbpasswd USER` | Change password |
| `sudo pdbedit -L` | List all SMB users |
| `sudo pdbedit -L -v USER` | Show user details |
| `sudo smbcontrol smbd reload-config` | Reload config without restart |

**Client Tools**

| Command | Action |
|---------|--------|
| `smbclient -L //SERVER` | List shares on server |
| `smbclient //SERVER/SHARE -U USER` | Connect to share |
| `smbclient //SERVER/SHARE -c 'CMD1; CMD2'` | Scripted smbclient |
| `smbclient -k //SERVER/SHARE` | Connect with Kerberos |
| `mount -t cifs //SERVER/SHARE /MNT -o OPTIONS` | Mount CIFS share |
| `umount /MNT` | Unmount CIFS share |

**Monitoring**

| Command | Action |
|---------|--------|
| `smbstatus` | Show all connections and locks |
| `smbstatus -L` | Show only locks |
| `smbstatus -p` | Show only processes |
| `smbstatus -S` | Show only shares |
| `smbcontrol smbd close-share NAME` | Disconnect all users from share |

**Winbind**

| Command | Action |
|---------|--------|
| `wbinfo -p` | Ping winbindd |
| `wbinfo -t` | Check domain trust |
| `wbinfo -u` | List domain users |
| `wbinfo -g` | List domain groups |
| `wbinfo -i USER` | Get user info |
| `wbinfo -n USER` | Get SID for username |
| `wbinfo -S SID` | Get UID from SID |
| `wbinfo -s SID` | Get username from SID |
| `getent passwd` | Show all users (including domain) |
| `getent group` | Show all groups (including domain) |

**Samba Config Parameters**

| Parameter | Purpose |
|-----------|---------|
| `workgroup` | NetBIOS workgroup/domain name |
| `server string` | Server description |
| `security` | User, share, ADS, domain |
| `server role` | Standalone, member, dc |
| `server min protocol` | Minimum SMB protocol version |
| `map to guest` | Guest access policy |
| `log level` | Debug verbosity |

### ⭐ Level 3 Commands: AD DC, Security, and Performance

**Active Directory DC**

| Command | Action |
|---------|--------|
| `sudo samba-tool domain provision` | Provision a new AD domain |
| `sudo samba-tool domain join` | Join an existing domain as DC |
| `sudo samba-tool user create USER` | Create AD user |
| `sudo samba-tool group add GROUP` | Create AD group |
| `sudo samba-tool dns add` | Add DNS record |
| `sudo samba-tool domain level show` | Show domain/forest level |
| `sudo samba-tool domain info IP` | Show domain info |

**Advanced Config Parameters**

| Parameter | Purpose |
|-----------|---------|
| `realm` | Kerberos realm (for ADS) |
| `server smb encrypt` | Encryption policy |
| `server signing` | Signing policy |
| `socket options` | TCP performance tuning |
| `disable netbios` | Disable NetBIOS ports 137-139 |
| `idmap config * : backend` | ID mapping backend |
| `idmap config * : range` | UID/GID range for mapping |
| `winbind use default domain` | Strip domain prefix from usernames |

---

## 🚀 What's Coming in Part 30

**Part 30: RAID — Redundant Array of Independent Disks**

You will learn:
- RAID levels 0, 1, 5, 6, 10 — how they work, striping, mirroring, parity
- Software RAID with mdadm — creating, managing, monitoring arrays
- Hardware RAID vs software RAID vs ZFS
- RAID superblock format, assembly, and recovery
- Hot spare drives and failure simulation
- Performance benchmarks across RAID levels
- Monitoring RAID health with mdstat, smartctl, and email alerts
- Recovery procedures — replacing failed drives, rebuilding arrays
- 15 hands-on practices

---

## 📝 Self-Test — Can You Answer These?

1. What are the three major versions of the SMB protocol, and which one should be disabled for security?
2. What is the difference between port 139 and port 445 in SMB networking?
3. What does `testparm` do and why should you run it before restarting Samba?
4. How do you add a user to Samba's password database? What is the difference between the system password and the SMB password?
5. In a Samba share definition, what do `create mask` and `directory mask` control?
6. What does `security = ADS` do and what other settings must be configured with it?
7. How does Winbind make Windows domain users appear in Linux commands like `getent passwd`?
8. What is the purpose of the `idmap config` directives?
9. How do you mount a CIFS share persistently via `/etc/fstab` and why should you use a credentials file?
10. What information does `smbstatus` show and how would you use it to find who has a file locked?
11. What is an SMB oplock and how does it affect file caching?
12. How does the SMB2/3 credit system improve performance over SMB1?
13. What are the security implications of SMB1 and how do you disable it in smb.conf?
14. In Samba AD DC mode, what services does `samba-ad-dc` replace from Windows Server?
15. What is SMB3 multichannel and how does it achieve higher throughput?

**Score:** 12/15 correct = ready for Part 30.

---

*Linux SysAdmin Course | Part 29 of ∞ | Reverse Engineering Approach*
*Previous → Part 28: Network File System (NFS)*
*Next → Part 30: RAID — Redundant Array of Independent Disks*

[← Previous](part28.md) | [Next →](part30.md)
