## 🔧 Section 3: OpenLDAP Configuration (cn=config)

### 3.1 OLC — Online Configuration

OLC allows you to modify the LDAP server **while it is running**. Changes are stored in LDAP entries under `cn=config`.

```
cn=config
├── cn=module{0}
├── cn=schema
│   ├── cn={0}core
│   ├── cn={1}cosine
│   ├── cn={2}nis
│   └── cn={3}inetorgperson
└── olcDatabase={-1}frontend
    └── olcDatabase={0}mdb
        └── olcDatabase={1}monitor
```

### 3.2 Key OLC Attributes

| Attribute | Purpose |
|-----------|---------|
| `olcSuffix` | The DN this database serves (e.g. `dc=example,dc=com`) |
| `olcRootDN` | The admin DN that can do anything on this database |
| `olcRootPW` | Password for the root DN (plaintext or SSHA hash) |
| `olcDbDirectory` | Where the MDB database files live |
| `olcAccess` | Access control rules |
| `olcLogLevel` | What slapd logs (stats, sync, conns, etc.) |

### 3.3 Configure via LDIF

**Never** edit the files under `cn=config` directly with a text editor. Use `ldapmodify`.

```bash
# Create rootpw.ldif
cat > rootpw.ldif << 'EOF'
dn: olcDatabase={0}mdb,cn=config
changetype: modify
replace: olcRootPW
olcRootPW: {SSHA}yourhashedpasswordhere
EOF

# Generate SSHA hash
slappasswd -s mysecretpassword
# {SSHA}xt9kQzG9H4qM7U0R3zX8n2L5cV7bN1

# Apply
ldapmodify -Y EXTERNAL -H ldapi:/// -f rootpw.ldif
```

### 3.4 Add a Suffix

```bash
cat > suffix.ldif << 'EOF'
dn: olcDatabase={0}mdb,cn=config
changetype: modify
replace: olcSuffix
olcSuffix: dc=example,dc=com
-
replace: olcRootDN
olcRootDN: cn=admin,dc=example,dc=com
EOF

ldapmodify -Y EXTERNAL -H ldapi:/// -f suffix.ldif
```

### 3.5 View Current Configuration

```bash
# List all databases
ldapsearch -Y EXTERNAL -H ldapi:/// -b cn=config \
  '(objectClass=olcDatabaseConfig)' dn

# Show full config of the MDB database
ldapsearch -Y EXTERNAL -H ldapi:/// -b olcDatabase={0}mdb,cn=config
```

### 3.6 Logging

```bash
cat > logging.ldif << 'EOF'
dn: cn=config
changetype: modify
replace: olcLogLevel
olcLogLevel: stats sync conns
EOF

ldapmodify -Y EXTERNAL -H ldapi:/// -f logging.ldif

# View logs
sudo journalctl -u slapd -f
```

---



---

[← Previous](04-level-2-intermediary-configuring-and.md) | [↑ Index](index.md) | [Next →](06-section-4-ldap-data-interchange.md)
