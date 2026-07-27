## ⚙️ Section 2: OpenLDAP Installation

### 2.1 What is OpenLDAP?

OpenLDAP is the open-source implementation of LDAP for Linux. It consists of:

- **slapd** — the LDAP server daemon (Standalone LDAP Daemon)
- **slurpd** — replication daemon (deprecated, now built into slapd)
- **ldap-utils** — client tools: `ldapsearch`, `ldapadd`, `ldapmodify`, `ldapdelete`, `ldapwhoami`

### 2.2 Installation (Debian/Ubuntu)

```bash
sudo apt update
sudo apt install -y slapd ldap-utils

# During install, dpkg will ask for an admin password.
# If you skip or want to reconfigure:
sudo dpkg-reconfigure slapd
```

The `dpkg-reconfigure slapd` wizard asks:

1. **Omit OpenLDAP server configuration?** → No
2. **DNS domain name?** → `example.com` (this becomes `dc=example,dc=com`)
3. **Organization name?** → `Example Inc`
4. **Administrator password?** → (set a strong one)
5. **Database backend?** → `MDB`
6. **Remove database when purge?** → No
7. **Move old database?** → Yes

### 2.3 Verify Installation

```bash
# Check slapd is running
systemctl status slapd

# Check listening ports
sudo netstat -tlnp | grep slapd
# 389/tcp  — LDAP (unencrypted)
# 636/tcp  — LDAPS (encrypted)

# Search the default directory
ldapsearch -x -H ldap://localhost -b dc=example,dc=com
```

### 2.4 The cn=config Backend

Modern OpenLDAP stores its configuration under `/etc/ldap/slapd.d/cn=config/`. This is the **Online Configuration (OLC)** system. Each configuration file is an LDIF-like file.

```bash
ls -la /etc/ldap/slapd.d/cn=config/
```

### 2.5 Installation on RHEL/CentOS

```bash
# RHEL 8/9
sudo dnf install -y openldap-servers openldap-clients
sudo systemctl enable --now slapd

# Initialize the database
sudo slaptest -u -f /etc/openldap/slapd.conf

# RHEL still uses slapd.conf by default; convert to cn=config
sudo slaptest -f /etc/openldap/slapd.conf -F /etc/openldap/slapd.d/
```

---



---

[← Previous](02-section-1-what-is-ldap.md) | [↑ Index](index.md) | [Next →](04-level-2-intermediary-configuring-and.md)
