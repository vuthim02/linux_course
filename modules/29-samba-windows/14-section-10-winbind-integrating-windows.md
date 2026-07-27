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



---

[← Previous](13-section-9-smbstatus-view-active.md) | [↑ Index](index.md) | [Next →](15-section-11-security-hardening-samba.md)
