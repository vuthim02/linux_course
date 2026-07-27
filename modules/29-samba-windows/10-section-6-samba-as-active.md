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



---

[← Previous](09-section-5-samba-as-nt4-style.md) | [↑ Index](index.md) | [Next →](11-section-7-linux-mounting-cifs.md)
