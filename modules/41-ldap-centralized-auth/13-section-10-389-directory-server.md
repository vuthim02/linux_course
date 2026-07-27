## 🏢 Section 10: 389 Directory Server (Red Hat)

### 10.1 What is 389 DS?

**389 Directory Server** is Red Hat's enterprise LDAP server. It is the upstream for Red Hat Directory Server and is used in FreeIPA.

### 10.2 Key Differences from OpenLDAP

| Aspect | OpenLDAP | 389 DS |
|--------|----------|--------|
| Configuration | OLC (cn=config) | `dsconf` CLI, Cockpit Web UI, INF files |
| Backend | MDB | Berkeley DB (LMDB in newer versions) |
| Plugins | Overlays | Plugins (pre/post operation, internal) |
| Schema | LDIF schema files | 95+ standard schemas included |
| Management | LDIF edits, ldapmodify | dsconf, Cockpit, REST API |

### 10.3 Installation (RHEL 8/9)

```bash
sudo dnf install -y 389-ds-base 389-ds-base-snmp 389-admin

# Create instance
sudo dscreate from-template
# or interactive:
sudo dscreate interactive
```

### 10.4 dscreate Template

```bash
# Generate template
dscreate create-template /root/ds-template.inf

# Edit template
cat /root/ds-template.inf
[general]
config_version = 2

[slapd]
root_password = verysecret
port = 389
secure_port = 636
self_sign_cert = True

[backend-userroot]
create_suffix_entry = True
suffix = dc=example,dc=com
```

```bash
# Create instance from template
sudo dscreate from-file /root/ds-template.inf

# Start and enable
sudo systemctl enable --now dirsrv@localhost
```

### 10.5 dsconf Management

```bash
# List instances
sudo dsconf list

# Create suffix
sudo dsconf instance localhost backend create \
  --suffix dc=example,dc=com --be-name example

# Add user
sudo dsconf instance localhost user create \
  --uid alice --cn "Alice Smith" --uid-number 10001

# Enable TLS
sudo dsconf instance localhost security enable \
  --cert-name server-cert

# Export LDIF
sudo dsconf instance localhost backend export \
  --be example --ldif-file /tmp/export.ldif

# Import LDIF
sudo dsconf instance localhost backend import \
  --be example --ldif-file /tmp/import.ldif
```

### 10.6 Cockpit UI

```bash
sudo dnf install -y cockpit cockpit-389-ds

# Enable and start
sudo systemctl enable --now cockpit.socket

# Access at https://your-server:9090
# Login as root or sudo user
# Click "389 Directory Server" in the admin menu
```

---



---

[← Previous](12-section-9-openldap-replication.md) | [↑ Index](index.md) | [Next →](14-section-11-sssd-system-security.md)
