## 🔁 Section 9: OpenLDAP Replication

### 9.1 Why Replicate?

- **High availability** — if one server dies, clients use another
- **Load balancing** — spread read queries across servers
- **Geographic distribution** — servers close to users
- **Backup** — read-only copy for disaster recovery

### 9.2 Replication Modes

| Mode | Description |
|------|-------------|
| **Provider → Consumer** | One-way sync. Provider pushes changes to consumers. |
| **MirrorMode** | Two providers accept writes, sync to each other. |
| **Syncrepl** | Consumer pulls changes from provider. |
| **Delta-syncrepl** | Sync only the changes (not the full entry). More efficient. |
| **RefreshAndPersist** | Consumer gets full refresh, then stays connected for real-time updates. |
| **RefreshOnly** | Consumer refreshes periodically (polling). |

### 9.3 Provider Configuration

On the **primary LDAP server** (provider):

```bash
cat > provider.ldif << 'EOF'
# Load syncprov module
dn: cn=module{0},cn=config
changetype: modify
add: olcModuleLoad
olcModuleLoad: syncprov

# Add syncprov overlay to the database
dn: olcOverlay=syncprov,olcDatabase={0}mdb,cn=config
changetype: add
objectClass: olcOverlayConfig
objectClass: olcSyncProvConfig
olcOverlay: syncprov
olcSpCheckpoint: 100 10
olcSpSessionLog: 100
EOF

ldapmodify -Y EXTERNAL -H ldapi:/// -f provider.ldif
```

### 9.4 Consumer Configuration

On the **replica LDAP server** (consumer):

```bash
cat > consumer.ldif << 'EOF'
dn: olcDatabase={0}mdb,cn=config
changetype: modify
replace: olcSuffix
olcSuffix: dc=example,dc=com
-
replace: olcRootDN
olcRootDN: cn=admin,dc=example,dc=com
-
replace: olcRootPW
olcRootPW: {SSHA}hashofadminpassword
-
replace: olcSyncrepl
olcSyncrepl: rid=001 provider=ldap://192.168.1.10:389 \
  binddn="cn=admin,dc=example,dc=com" \
  credentials="adminpassword" \
  searchbase="dc=example,dc=com" \
  schemachecking=on \
  type=refreshAndPersist \
  retry="60 +"
EOF

ldapmodify -Y EXTERNAL -H ldapi:/// -f consumer.ldif
```

### 9.5 Delta-syncrepl

More efficient — only syncs actual changes:

```bash
cat > delta-provider.ldif << 'EOF'
dn: olcOverlay=syncprov,olcDatabase={0}mdb,cn=config
changetype: modify
replace: olcSpCheckpoint
olcSpCheckpoint: 100 10

# Also need accesslog overlay
dn: cn=module{0},cn=config
changetype: modify
add: olcModuleLoad
olcModuleLoad: accesslog
EOF
```

### 9.6 Verify Replication

```bash
# On consumer — should show entries from provider
ldapsearch -x -H ldap://consumer-host -b dc=example,dc=com

# Check sync status on provider
ldapsearch -Y EXTERNAL -H ldapi:/// -b 'cn=accesslog'

# Check consumer sync context
ldapsearch -Y EXTERNAL -H ldapi:/// -b 'olcDatabase={0}mdb,cn=config' olcSyncRepl
```

---



---

[← Previous](11-level-3-advanced-ldap-internals.md) | [↑ Index](index.md) | [Next →](13-section-10-389-directory-server.md)
