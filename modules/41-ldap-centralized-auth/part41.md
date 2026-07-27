# 🐧 Linux System Administrator — Complete Course
## Part 41 of ∞: LDAP and Centralized Authentication

---

> **Reverse Engineering Approach:** In the real world, you will inherit LDAP servers already running. You will debug why `getent passwd` returns nothing, why `ldapsearch` times out, why TLS handshakes fail. This part teaches you to **read configs, decode errors, and fix broken auth** — skills every sysadmin needs. You'll build a full LDAP authentication server from scratch, then deliberately break and fix it.

---

![LDAP directory information tree (DIT) — hierarchical entry structure](https://upload.wikimedia.org/wikipedia/commons/3/3e/Datenstruktur.png)

*LDAP directory tree structure (Denny-pug / Wikimedia Commons / CC-BY-SA-3.0)*

## ⭐ Level 1: Basic — Understanding LDAP Concepts

![LDAP Directory Information Tree — hierarchical entry structure](https://upload.wikimedia.org/wikipedia/commons/3/3e/Datenstruktur.png)

> **Level 1 Goal:** Understand what LDAP is, its core concepts (DIT, DN, RDN, objectClass), the LDIF format, and how to install OpenLDAP.

## 📦 Section 1: What is LDAP?

### 1.1 The Problem LDAP Solves

On a single Linux machine, users are stored in `/etc/passwd` and `/etc/shadow`. With 10 servers, you copy those files (manually or with scripts). With 100 servers, that is impossible. You need **centralized authentication** — one database of users that every server queries.

**LDAP** = Lightweight Directory Access Protocol. It is the industry standard for:

- Centralized user/group storage
- Address books (email, phone, org charts)
- Network device authentication
- Certificate and key storage
- Application configuration directories

LDAP is *not* a relational database. It is optimized for **read-heavy, hierarchical lookups**, not for transactions or complex joins.

### 1.2 X.500 and the DIT

LDAP is descended from the X.500 OSI directory standard. X.500 defined the **Directory Information Tree (DIT)** — a tree of entries.

```
                           dc=example,dc=com
                              │
                ┌─────────────┼─────────────┐
                │             │             │
           ou=People     ou=Groups     ou=Services
                │             │             │
        ┌───────┼───────┐    │             │
        │       │       │  cn=admins    cn=ldap
    uid=alice uid=bob uid=carol
```

Each node is an **entry**. Each entry has:

- **Distinguished Name (DN)** — unique path in the tree (e.g. `uid=alice,ou=People,dc=example,dc=com`)
- **Relative Distinguished Name (RDN)** — the leftmost component (`uid=alice`)
- **Attributes** — key-value pairs (`cn: Alice Smith`, `mail: alice@example.com`)
- **objectClass** — defines which attributes are allowed or required

### 1.3 LDIF Format

LDAP Data Interchange Format (LDIF) is the plaintext format for LDAP entries:

```ldif
dn: uid=alice,ou=People,dc=example,dc=com
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
cn: Alice Smith
sn: Smith
uid: alice
uidNumber: 10001
gidNumber: 10001
homeDirectory: /home/alice
loginShell: /bin/bash
userPassword: {SSHA}abcdef123456...
mail: alice@example.com
```

### 1.4 Key LDAP Jargon

| Term | Meaning |
|------|---------|
| **DIT** | Directory Information Tree — the hierarchical namespace |
| **DN** | Distinguished Name — full path to an entry |
| **RDN** | Relative Distinguished Name — the entry's own name component |
| **objectClass** | Template defining which attributes an entry must/may have |
| **Attribute** | A key-value pair (e.g. `cn: Alice Smith`) |
| **Entry** | A single node in the DIT |
| **Bind** | LDAP authentication (prove who you are) |
| **Base DN** | The root of the search (e.g. `dc=example,dc=com`) |
| **Scope** | How deep to search: base, onelevel, or subtree |
| **Filter** | Search criteria like `(uid=alice)` |

### 1.5 When to Use LDAP vs. Other Solutions

| Solution | Best For |
|----------|----------|
| **LDAP** | Large-scale user directories, address books, PKI |
| **Kerberos** | Authentication only (fast, secure, single sign-on) |
| **FreeIPA** | All-in-one (LDAP + Kerberos + DNS + CA) |
| **SSSD** | Client-side cache for any identity provider |
| **NIS** | Legacy small networks (do not deploy new) |
| **SSH keys** | Small teams, no central management |

---

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

## ⭐ Level 2: Intermediary — Configuring and Managing OpenLDAP

![OpenLDAP logo — the open-source LDAP directory server](https://upload.wikimedia.org/wikipedia/commons/thumb/8/84/OpenLDAP_logo.svg/800px-OpenLDAP_logo.svg.png)

> **Level 2 Goal:** Configure OpenLDAP using OLC, manage entries with LDIF, set up schemas, integrate with PAM/NSS for authentication, enable TLS, and use browser tools.

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

## 📄 Section 4: LDAP Data Interchange Format (LDIF)

### 4.1 LDIF Syntax Rules

```
# Comments start with #
dn: <distinguished name>
<attribute>: <value>
<attribute>;lang-en: <value with language tag>
<attribute>:: <base64-encoded value>

# Blank line separates entries
dn: cn=next entry,dc=example,dc=com
```

- Lines starting with a space are continuations of the previous line
- Attribute names are case-insensitive
- DNs are case-insensitive (but preserve case for display)
- Binary values use `::` followed by base64

### 4.2 Adding Entries

```bash
cat > base.ldif << 'EOF'
dn: dc=example,dc=com
objectClass: top
objectClass: dcObject
objectClass: organization
o: Example Inc
dc: example

dn: cn=admin,dc=example,dc=com
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: admin
description: LDAP administrator
userPassword: {SSHA}xt9kQzG9H4qM7U0R3zX8n2L5cV7bN1

dn: ou=People,dc=example,dc=com
objectClass: organizationalUnit
ou: People

dn: ou=Groups,dc=example,dc=com
objectClass: organizationalUnit
ou: Groups
EOF

ldapadd -x -D cn=admin,dc=example,dc=com -W -f base.ldif
```

### 4.3 Adding Users

```bash
cat > users.ldif << 'EOF'
dn: uid=alice,ou=People,dc=example,dc=com
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
cn: Alice Smith
sn: Smith
uid: alice
uidNumber: 10001
gidNumber: 10001
homeDirectory: /home/alice
loginShell: /bin/bash
userPassword: {SSHA}hash
mail: alice@example.com

dn: uid=bob,ou=People,dc=example,dc=com
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
cn: Bob Jones
sn: Jones
uid: bob
uidNumber: 10002
gidNumber: 10002
homeDirectory: /home/bob
loginShell: /bin/bash
userPassword: {SSHA}hash
mail: bob@example.com
EOF

ldapadd -x -D cn=admin,dc=example,dc=com -W -f users.ldif
```

### 4.4 Adding Groups

```bash
cat > groups.ldif << 'EOF'
dn: cn=developers,ou=Groups,dc=example,dc=com
objectClass: posixGroup
cn: developers
gidNumber: 10001
memberUid: alice
memberUid: bob

dn: cn=admins,ou=Groups,dc=example,dc=com
objectClass: posixGroup
cn: admins
gidNumber: 5000
memberUid: alice
EOF

ldapadd -x -D cn=admin,dc=example,dc=com -W -f groups.ldif
```

### 4.5 Modifying Entries

```bash
# Add an attribute
cat > addmail.ldif << 'EOF'
dn: uid=bob,ou=People,dc=example,dc=com
changetype: modify
add: telephoneNumber
telephoneNumber: +1-555-1234
EOF

ldapmodify -x -D cn=admin,dc=example,dc=com -W -f addmail.ldif

# Replace an attribute
cat > replacemail.ldif << 'EOF'
dn: uid=bob,ou=People,dc=example,dc=com
changetype: modify
replace: mail
mail: bob.jones@example.com
EOF

ldapmodify -x -D cn=admin,dc=example,dc=com -W -f replacemail.ldif

# Delete an attribute
cat > delmail.ldif << 'EOF'
dn: uid=bob,ou=People,dc=example,dc=com
changetype: modify
delete: telephoneNumber
EOF

ldapmodify -x -D cn=admin,dc=example,dc=com -W -f delmail.ldif
```

### 4.6 Deleting Entries

```bash
ldapdelete -x -D cn=admin,dc=example,dc=com -W \
  'uid=bob,ou=People,dc=example,dc=com'

# Delete subtree (add -r)
ldapdelete -x -D cn=admin,dc=example,dc=com -W -r \
  'ou=People,dc=example,dc=com'
```

### 4.7 LDIF Format: changetype: delete

```ldif
dn: uid=bob,ou=People,dc=example,dc=com
changetype: delete
```

### 4.8 LDIF Format: changetype: modrdn (rename)

```ldif
dn: uid=bob,ou=People,dc=example,dc=com
changetype: modrdn
newrdn: uid=robert
deleteoldrdn: 1
newsuperior: ou=Contractors,dc=example,dc=com
```

---

## 📐 Section 5: LDAP Schemas

### 5.1 What is a Schema?

A schema defines:

- **objectClasses** — templates for entries (e.g. you must have `cn`, you may have `mail`)
- **AttributeTypes** — definitions of attributes (e.g. `cn` is a case-ignore string, `uidNumber` is an integer)

### 5.2 Standard Schemas

| Schema File | Contents |
|-------------|----------|
| `core.schema` | Top, person, organizationalUnit, dcObject, etc. |
| `cosine.schema` | Pilot object classes (pilotPerson, etc.) |
| `nis.schema` | posixAccount, shadowAccount, posixGroup (Unix users/groups) |
| `inetorgperson.schema` | inetOrgPerson (extended person with email, phone, etc.) |
| `collective.schema` | Collective attributes (shared across entries) |
| `corba.schema` | CORBA object references |
| `openldap.schema` | OpenLDAP-specific object classes |

### 5.3 View Loaded Schemas

```bash
ldapsearch -Y EXTERNAL -H ldapi:/// -b cn=schema,cn=config dn
# cn={0}core
# cn={1}cosine
# cn={2}nis
# cn={3}inetorgperson
```

### 5.4 Schema Inheritance

```
top                    # Every entry has this
├── person             # cn, sn (required); description, seeAlso (optional)
│   └── organizationalPerson
│       └── inetOrgPerson  # Adds mail, telephoneNumber, employeeID, etc.
├── organizationalRole  # cn, description
├── organizationalUnit  # ou
├── dcObject            # dc
├── posixAccount        # uid, uidNumber, gidNumber, homeDirectory, ...
├── shadowAccount       # shadowLastChange, shadowMin, shadowMax, ...
└── posixGroup          # cn, gidNumber, memberUid
```

An entry can have **multiple objectClasses**. For example, a user entry uses `inetOrgPerson` for contact info, `posixAccount` for Unix attributes, and `shadowAccount` for password aging.

### 5.5 Custom Schema Example

```bash
cat > mycompany.schema << 'EOF'
# Attribute definitions
attributetype ( 1.3.6.1.4.1.99999.1.1
    NAME 'employeeID'
    DESC 'Company employee ID'
    SYNTAX 1.3.6.1.4.1.1466.115.121.1.15
    SINGLE-VALUE )

attributetype ( 1.3.6.1.4.1.99999.1.2
    NAME 'departmentNumber'
    DESC 'Department code'
    SYNTAX 1.3.6.1.4.1.1466.115.121.1.15 )

attributetype ( 1.3.6.1.4.1.99999.1.3
    NAME 'dateOfHire'
    DESC 'Date the employee was hired'
    SYNTAX 1.3.6.1.4.1.1466.115.121.1.24
    SINGLE-VALUE )

# ObjectClass definition
objectclass ( 1.3.6.1.4.1.99999.2.1
    NAME 'myCompanyEmployee'
    DESC 'Example Inc employee'
    SUP inetOrgPerson
    AUXILIARY
    MUST ( employeeID )
    MAY ( departmentNumber $ dateOfHire $ emergencyContact ) )
EOF

# Install schema (convert to LDIF and add to cn=config)
sudo cp mycompany.schema /etc/ldap/schema/
sudo slapcat -f mycompany.conv.conf -F /tmp/ldap-schema-out
```

In practice, converting `.schema` to `.ldif` for `cn=config` requires the `slapd-schema-manager` or manual conversion:

```bash
# Convert schema to LDIF
sudo slapcat -f /dev/null -F /etc/ldap/slapd.d/ \
  -o ldif-wrap=no -n 0 | grep -A 1000 "cn={0}core" > convert.ldif
```

The simpler modern approach is to use `ldapadd` with a properly crafted LDIF:

```bash
cat > mycompany-oid.ldif << 'EOF'
# This is complex — in practice, use the schema file approach above
# or use Apache Directory Studio to manage schemas visually
EOF
```

### 5.6 OID Registration

Every attribute and objectClass needs a globally unique **Object Identifier (OID)**. You can:

- Get a free OID from IANA (enterprise numbers)
- Use a private OID range under `1.3.6.1.4.1.<your-enterprise-number>`
- Use OIDs from your national OID authority

---

## 🔐 Section 6: LDAP Authentication (PAM and NSS)

### 6.1 The Authentication Stack

```
Application (login, ssh, su, sudo)
        │
        ▼
    ┌─────┐
    │ PAM │  Pluggable Authentication Modules
    └─────┘
        │
        ▼
    ┌─────┐
    │ NSS │  Name Service Switch
    └─────┘
        │
        ▼
    ┌──────┐
    │ nslcd│  LDAP client daemon → LDAP server
    └──────┘
```

### 6.2 PAM (Pluggable Authentication Modules)

PAM controls **authentication** (proving who you are). Config files are in `/etc/pam.d/`.

Three key files:

| File | Controls |
|------|----------|
| `common-auth` | Authentication process (password prompts) |
| `common-account` | Account management (account expiry, access times) |
| `common-password` | Password changes |
| `common-session` | Session setup (home dir creation, mounts) |

### 6.3 NSS (Name Service Switch)

NSS controls **lookup** (getting user/group info). Config file is `/etc/nsswitch.conf`.

```
passwd:         compat systemd ldap
group:          compat systemd ldap
shadow:         compat ldap
```

### 6.4 Installation of LDAP Auth Modules (Debian/Ubuntu)

```bash
sudo apt install -y libnss-ldapd libpam-ldapd

# During installation, you'll be prompted:
# 1. LDAP server URI: ldap://192.168.1.10
# 2. Base DN: dc=example,dc=com
# 3. LDAP version: 3
# 4. Make local root DB admin: Yes
# 5. Enable NSS databases: passwd, group, shadow
```

### 6.5 nslcd Configuration

The `nslcd` daemon connects to LDAP on behalf of PAM/NSS.

```bash
cat /etc/nslcd.conf
# /etc/nslcd.conf
# nslcd configuration file

uid nslcd
gid nslcd

uri ldap://192.168.1.10/
base dc=example,dc=com
ldap_version 3

# Bind DN (read-only user for lookups)
binddn cn=admin,dc=example,dc=com
bindpw adminpassword

# SSL options
ssl off
tls_cacertfile /etc/ssl/certs/ca-certificates.crt

# Filter options
filter passwd (objectClass=posixAccount)
filter group (objectClass=posixGroup)

# Map attributes
map passwd uid uid
map passwd homeDirectory homeDirectory
```

### 6.6 Verify NSS Integration

```bash
# These should now show LDAP users
getent passwd alice
getent group developers
id alice

# If nslcd is not running
systemctl restart nslcd
systemctl status nslcd
```

### 6.7 PAM Configuration

On Debian/Ubuntu, PAM modules are stacked. The LDAP module is inserted automatically by `pam-auth-update`:

```bash
sudo pam-auth-update

# Enable:
# [*] LDAP Authentication
# [*] LDAP Accounts
# [*] LDAP Password
# [*] LDAP Session
```

Manual `/etc/pam.d/common-auth` example:

```
auth    [success=1 default=ignore]  pam_unix.so nullok_secure
auth    requisite                   pam_deny.so
auth    required                    pam_permit.so
auth    optional                    pam_cap.so
```

After installing `libpam-ldapd`, `pam-auth-update` adds:

```
auth    sufficient                    pam_ldap.so
auth    required                      pam_unix.so nullok_secure try_first_pass
```

### 6.8 Testing LDAP Authentication

```bash
# Test authentication from command line
su - alice

# SSH login from another machine
ssh alice@ldap-client

# Check PAM debug logs
journalctl -u sshd | grep -i ldap
```

### 6.9 Client Configuration for Red Hat/CentOS

```bash
# RHEL uses authconfig or authselect
sudo dnf install -y authselect oddjob-mkhomedir
sudo authselect select sssd with-mkhomedir --force

# Or for direct LDAP (deprecated approach)
sudo authconfig --enableldap \
  --enableldapauth \
  --ldapserver=ldap://192.168.1.10 \
  --ldapbasedn="dc=example,dc=com" \
  --updateall
```

---

## 🔒 Section 7: LDAP over TLS

### 7.1 Why TLS for LDAP?

Without TLS, all authentication traffic (including passwords) is sent **in plaintext** over the network. TLS provides:

- Encryption (passwords, data)
- Server identity verification (certificates)
- Data integrity (tamper detection)

### 7.2 Create a Self-Signed CA and Certificate

```bash
# Create CA key and cert
sudo mkdir -p /etc/ldap/ssl
sudo openssl genrsa -out /etc/ldap/ssl/ca-key.pem 4096
sudo openssl req -new -x509 -days 3650 \
  -key /etc/ldap/ssl/ca-key.pem \
  -out /etc/ldap/ssl/ca-cert.pem \
  -subj "/C=US/ST=State/L=City/O=Example Inc/CN=LDAP CA"

# Create server key
sudo openssl genrsa -out /etc/ldap/ssl/ldap-key.pem 4096

# Create certificate signing request
sudo openssl req -new \
  -key /etc/ldap/ssl/ldap-key.pem \
  -out /etc/ldap/ssl/ldap-req.pem \
  -subj "/C=US/ST=State/L=City/O=Example Inc/CN=ldap.example.com"

# Sign with CA
sudo openssl x509 -req -days 3650 \
  -in /etc/ldap/ssl/ldap-req.pem \
  -CA /etc/ldap/ssl/ca-cert.pem \
  -CAkey /etc/ldap/ssl/ca-key.pem \
  -CAcreateserial \
  -out /etc/ldap/ssl/ldap-cert.pem

# Set permissions
sudo chown -R openldap:openldap /etc/ldap/ssl
sudo chmod 600 /etc/ldap/ssl/ldap-key.pem
```

### 7.3 Enable TLS in slapd

```bash
cat > tls.ldif << 'EOF'
dn: cn=config
changetype: modify
add: olcTLSCACertificateFile
olcTLSCACertificateFile: /etc/ldap/ssl/ca-cert.pem
-
add: olcTLSCertificateFile
olcTLSCertificateFile: /etc/ldap/ssl/ldap-cert.pem
-
add: olcTLSKeyFile
olcTLSKeyFile: /etc/ldap/ssl/ldap-key.pem
EOF

ldapmodify -Y EXTERNAL -H ldapi:/// -f tls.ldif

# Restart slapd
sudo systemctl restart slapd
```

### 7.4 Force TLS for All Connections

```bash
cat > force-tls.ldif << 'EOF'
dn: olcDatabase={0}mdb,cn=config
changetype: modify
add: olcSecurity
olcSecurity: tls=1
EOF

ldapmodify -Y EXTERNAL -H ldapi:/// -f force-tls.ldif
```

### 7.5 Client Side: ldapsearch with TLS

```bash
# StartTLS (port 389, upgrade to TLS)
ldapsearch -x -H ldap://ldap.example.com -ZZ -b dc=example,dc=com

# LDAPS (port 636, TLS from start)
ldapsearch -x -H ldaps://ldap.example.com -b dc=example,dc=com

# If using self-signed CA, specify cert
LDAPTLS_CACERT=/etc/ldap/ssl/ca-cert.pem \
  ldapsearch -x -H ldaps://ldap.example.com -b dc=example,dc=com
```

### 7.6 Troubleshooting TLS

```bash
# Test TLS handshake
openssl s_client -connect ldap.example.com:636 -showcerts

# Check slapd TLS config
ldapsearch -Y EXTERNAL -H ldapi:/// -b cn=config 'olcTLS*'

# Verbose LDAP debug
LDAPDEBUG=1 ldapsearch -x -H ldap://ldap.example.com -ZZ
```

---

## 🔍 Section 8: LDAP Browser Tools

### 8.1 ldapsearch (Command Line)

The swiss-army knife of LDAP.

```bash
# Basic search
ldapsearch -x -H ldap://localhost -b dc=example,dc=com

# Filter by object class
ldapsearch -x -b dc=example,dc=com '(objectClass=posixAccount)'

# Return specific attributes
ldapsearch -x -b dc=example,dc=com '(uid=alice)' cn mail uidNumber

# Limit scope
ldapsearch -x -b ou=People,dc=example,dc=com -s one '(uid=*)'

# Show operational attributes (internal metadata)
ldapsearch -x -b dc=example,dc=com '+' '*'

# Authenticated search
ldapsearch -x -D cn=admin,dc=example,dc=com -W -b dc=example,dc=com

# Size and time limits
ldapsearch -x -b dc=example,dc=com -z 10 -l 5
```

**Search Filters Reference:**

| Filter | Matches |
|--------|---------|
| `(uid=alice)` | Exact match |
| `(uid=a*)` | Starts with 'a' |
| `(uid=*ice)` | Ends with 'ice' |
| `(uid=*li*)` | Contains 'li' |
| `(&(objectClass=person)(cn=A*))` | AND condition |
| `(\|(uid=alice)(uid=bob))` | OR condition |
| `(!(uid=alice))` | NOT condition |
| `(uid=~=alise)` | Approximate (sounds like) |
| `(memberOf=cn=admins,ou=Groups,...)` | Group membership |

### 8.2 ldapwhoami

```bash
# Check who you are authenticated as
ldapwhoami -x
# anonymous

ldapwhoami -D cn=admin,dc=example,dc=com -W
# dn:cn=admin,dc=example,dc=com
```

### 8.3 ldapcompare

```bash
ldapcompare -x 'uid=alice,ou=People,dc=example,dc=com' 'sn:Smith'
# TRUE

ldapcompare -x 'uid=alice,ou=People,dc=example,dc=com' 'sn:Jones'
# FALSE
```

### 8.4 Apache Directory Studio

A full-featured Eclipse-based LDAP browser:

```bash
# Download from https://directory.apache.org/studio/
# Or on Debian:
sudo apt install -y apache-directory-studio  # may not be in repos

# Features:
# - Browse DIT tree
# - Create/edit/delete entries graphically
# - LDIF editor with syntax highlighting
# - Schema browser
# - Connection profiles
# - Search builder
```

### 8.5 phpLDAPadmin

Web-based LDAP browser:

```bash
# On Debian/Ubuntu
sudo apt install -y phpldapadmin

# Access at http://your-server/phpldapadmin
# Config file: /etc/phpldapadmin/config.php

# Key settings to change:
$servers->setValue('server','host','localhost');
$servers->setValue('server','base',array('dc=example,dc=com'));
$servers->setValue('login','anon_bind',false);
$servers->setValue('login','dn','cn=admin,dc=example,dc=com');
```

---

## ⭐ Level 3: Advanced — LDAP Internals, Replication, and Enterprise Integration

![Kerberos protocol flow — ticket-based authentication diagram](https://upload.wikimedia.org/wikipedia/commons/thumb/4/4e/Kerberos_protocol.svg/800px-Kerberos_protocol.svg.png)

> **Level 3 Goal:** Implement LDAP replication with syncrepl, deploy 389 Directory Server, understand Kerberos authentication, integrate FreeIPA for identity management, and master deep protocol internals including ASN.1/BER encoding.

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

## 👤 Section 11: SSSD (System Security Services Daemon)

### 11.1 What is SSSD?

SSSD is a **client-side daemon** that connects to identity providers (LDAP, AD, Kerberos, FreeIPA) and caches credentials locally. It is the **modern replacement** for direct PAM/NSS LDAP integration.

```
Application → PAM → nss_sss → sssd → LDAP/Kerberos/AD
                            ↓
                      Cache (disk/memory)
```

### 11.2 Advantages of SSSD

- **Offline authentication** — users can log in when the LDAP server is unreachable (cached credentials)
- **Caching** — reduces load on LDAP server
- **Multiple domains** — connect to LDAP, AD, and FreeIPA simultaneously
- **Automatic failover** — multiple LDAP servers
- **Fast** — responses from cache instead of network
- **Centralized sudo rules** — via sudoProvider
- **SSH key distribution** — via sshKnownHostsProvider

### 11.3 Installation and Configuration

```bash
# Debian/Ubuntu
sudo apt install -y sssd sssd-ldap libpam-sss libnss-sss

# RHEL/CentOS
sudo dnf install -y sssd sssd-ldap oddjob-mkhomedir

# Create configuration
sudo vim /etc/sssd/sssd.conf
```

```ini
[sssd]
domains = example.com
services = nss, pam, ssh
config_file_version = 2

[domain/example.com]
id_provider = ldap
auth_provider = ldap
chpass_provider = ldap
access_provider = ldap

ldap_uri = ldap://192.168.1.10,ldap://192.168.1.11
ldap_search_base = dc=example,dc=com
ldap_id_use_start_tls = True
ldap_tls_cacert = /etc/ssl/certs/ca-certificates.crt

# Bind DN (read-only user for lookups)
ldap_default_bind_dn = cn=admin,dc=example,dc=com
ldap_default_authtok = adminpassword

# Cache settings
cache_credentials = True
entry_cache_timeout = 3600

# Home directories
override_homedir = /home/%u
override_shell = /bin/bash

# Sudo integration (optional)
sudo_provider = ldap
ldap_sudo_search_base = ou=sudoers,dc=example,dc=com
```

### 11.4 Post-Install Steps

```bash
# Fix permissions (SSSD refuses to start if permissions wrong)
sudo chmod 600 /etc/sssd/sssd.conf

# Enable autofs for home directories (optional)
sudo systemctl enable --now autofs

# Enable mkhomedir on login
# Debian:
sudo pam-auth-update --enable mkhomedir

# RHEL:
sudo authselect select sssd with-mkhomedir --force

# Start SSSD
sudo systemctl enable --now sssd

# Clear cache if needed
sudo systemctl stop sssd
sudo rm -rf /var/lib/sss/db/*
sudo systemctl start sssd
```

### 11.5 Verify SSSD

```bash
# Should return LDAP users
getent passwd alice
id alice

# Check SSSD status
sudo sssctl domain-status example.com

# Check if SSSD sees the domain
sudo sssctl domain-list

# Debug output
sudo sssctl debug-level 9
sudo journalctl -u sssd -f

# Force cache refresh
sudo sssctl cache-remove example.com
```

### 11.6 Troubleshooting SSSD

```bash
# Test LDAP connectivity
sssctl ldap-test

# Check NSS is using SSS
getent passwd alice  # Should work
grep sss /etc/nsswitch.conf
# passwd: compat systemd sss
# group:  compat systemd sss
# shadow: compat sss

# Check PAM config
grep pam_sss /etc/pam.d/common-auth

# If no results from getent:
sudo sssctl cache-remove
# Make sure nslcd is stopped (it conflicts with sssd)
sudo systemctl stop nslcd
sudo systemctl disable nslcd
```

---

## 🏛️ Section 12: FreeIPA

### 12.1 What is FreeIPA?

FreeIPA is an **integrated identity management solution** that combines:

- **389 Directory Server** (LDAP)
- **MIT Kerberos** (authentication)
- **BIND with DNSSEC** (DNS)
- **Dogtag Certificate System** (CA)
- **NTP** (time synchronization)
- **Web UI** (Cockpit-based management interface)

It provides a **one-stop shop** for domain management, similar to Microsoft Active Directory but for Linux/Unix environments.

### 12.2 When to Use FreeIPA vs. OpenLDAP

| Scenario | Recommendation |
|----------|---------------|
| Small team (10 users, 5 servers) | OpenLDAP + SSSD |
| Enterprise (500+ users, 100+ servers) | FreeIPA |
| Need single sign-on (Kerberos) | FreeIPA |
| Need certificate management | FreeIPA |
| Already have AD | SSSD with AD provider |
| Minimal, lightweight setup | OpenLDAP |

### 12.3 Installation (RHEL 8/9)

```bash
# Prerequisites
sudo hostnamectl set-hostname ipa.example.com
echo "192.168.1.10 ipa.example.com" >> /etc/hosts

# Install FreeIPA server
sudo dnf install -y freeipa-server freeipa-server-dns

# Run installer
sudo ipa-server-install \
  --realm=EXAMPLE.COM \
  --domain=example.com \
  --hostname=ipa.example.com \
  --ds-password=dspassword \
  --admin-password=adminpassword \
  --setup-dns \
  --no-forwarders \
  --unattended
```

### 12.4 Installation (Ubuntu)

```bash
sudo apt install -y freeipa-server freeipa-server-dns
sudo ipa-server-install
```

### 12.5 Basic FreeIPA Commands

```bash
# Authenticate as admin
kinit admin

# Add user
ipa user-add alice \
  --first=Alice --last=Smith \
  --email=alice@example.com \
  --password

# Add group
ipa group-add developers --desc="Development Team"

# Add user to group
ipa group-add-member developers --users=alice

# Search users
ipa user-find alice

# Show user details
ipa user-show alice

# Disable user
ipa user-disable alice

# Enable user
ipa user-enable alice

# Delete user
ipa user-del alice

# Add sudo rule
ipa sudorule-add full_admin \
  --hostcat=all --cmdcat=all --runasusercat=all

ipa sudorule-add-user full_admin --users=alice
```

### 12.6 FreeIPA Client Setup

```bash
# On each client machine
sudo dnf install -y freeipa-client

sudo ipa-client-install \
  --domain=example.com \
  --server=ipa.example.com \
  --realm=EXAMPLE.COM \
  --mkhomedir \
  --enable-dns-updates

# Verify
getent passwd alice
kinit alice
klist
```

### 12.7 FreeIPA Web UI

Access the web interface at `https://ipa.example.com/ipa/ui/`:

```
Active Users    ──────── User management
Policy          ──────── Password policies, HBAC, sudo
Authentication  ──────── Kerberos, OTP, certificates
Network Services ──────── DNS, NTP, services
Role-Based ACL  ──────── Delegation, roles, privileges
```

---

## 🎫 Section 13: Kerberos

### 13.1 What is Kerberos?

Kerberos is a **network authentication protocol** that uses **tickets** instead of passwords. It provides **single sign-on (SSO)** — you authenticate once and get tickets for all services.

Named after Cerberus, the three-headed dog guarding Hades (the three heads are AS, TGS, and the service).

### 13.2 How Kerberos Works — The Ticket Granting Process

```
┌─────────┐          ┌───────────┐          ┌────────────┐
│  User   │          │    AS     │          │    TGS     │
│ (Alice) │          │   Auth    │          │  Ticket    │
│         │          │  Server   │          │  Granting  │
└────┬────┘          └─────┬─────┘          └─────┬──────┘
     │                     │                       │
     │  1. Request TGT     │                       │
     │────────────────────>│                       │
     │                     │                       │
     │  2. TGT (encrypted  │                       │
     │   with KDC secret)  │                       │
     │<────────────────────│                       │
     │                     │                       │
     │  3. Request service │                       │
     │   ticket for SSH    │                       │
     │  (send TGT)         │                       │
     │────────────────────────────────────────────>│
     │                     │                       │
     │  4. Service ticket  │                       │
     │  (encrypted with    │                       │
     │   service secret)   │                       │
     │<────────────────────────────────────────────│
     │                     │                       │
     │  5. Present ticket  │                       │
     │   to SSH server     │                       │
     │  (authenticate)     │                       │
     │                                             │
```

**Step-by-step:**

| Step | From | To | What Happens |
|------|------|----|-------------|
| 1 | User | AS | User sends `kinit alice` → AS looks up in LDAP |
| 2 | AS | User | AS sends back **Ticket Granting Ticket (TGT)** encrypted with KDC master key |
| 3 | User | TGS | User wants to access SSH. Sends TGT + request for SSH service ticket |
| 4 | TGS | User | TGS sends service ticket for `host/server.example.com` |
| 5 | User | SSH | User presents service ticket. SSH decrypts with its keytab — access granted |

**Key Concepts:**

- **KDC** = Key Distribution Center (the combined AS + TGS)
- **Realm** = Kerberos domain (e.g. `EXAMPLE.COM`, uppercase by convention)
- **Principal** = A unique identity (`alice@EXAMPLE.COM`, `host/server.example.com@EXAMPLE.COM`)
- **Keytab** = A file containing service principals' long-term keys
- **TGT** = Ticket Granting Ticket (your "passport" — proves you authenticated)
- **Service Ticket** = Ticket for a specific service (SSH, HTTP, NFS)

### 13.3 Kerberos Configuration

```ini
# /etc/krb5.conf
[libdefaults]
  default_realm = EXAMPLE.COM
  dns_lookup_realm = true
  dns_lookup_kdc = true
  ticket_lifetime = 24h
  renew_lifetime = 7d
  forwardable = true
  rdns = false

[realms]
  EXAMPLE.COM = {
    kdc = kdc.example.com:88
    admin_server = kdc.example.com:749
    default_domain = example.com
  }

[domain_realm]
  .example.com = EXAMPLE.COM
  example.com = EXAMPLE.COM
```

### 13.4 kinit, klist, kdestroy

```bash
# Authenticate and get a TGT
kinit alice@EXAMPLE.COM
# (enter password)

# List active tickets
klist
# Ticket cache: FILE:/tmp/krb5cc_10001
# Default principal: alice@EXAMPLE.COM
#
# Valid starting     Expires            Service principal
# 06/24/26 10:00:00  06/25/26 10:00:00  krbtgt/EXAMPLE.COM@EXAMPLE.COM
#         renew until 07/01/26 10:00:00

# Detailed view
klist -e
# Shows encryption types

# List all tickets including service tickets
klist -A

# Check if authentication is valid
kvno alice@EXAMPLE.COM

# Destroy tickets (logout)
kdestroy

# Destroy all tickets
kdestroy -A
```

### 13.5 kadmin (Kerberos Admin)

```bash
# Access admin interface
kadmin -p admin/admin@EXAMPLE.COM

# Inside kadmin:
kadmin: addprinc alice@EXAMPLE.COM
kadmin: addprinc -randkey host/server.example.com@EXAMPLE.COM
kadmin: ktadd -k /etc/krb5.keytab host/server.example.com@EXAMPLE.COM
kadmin: listprincs
kadmin: delprinc bob@EXAMPLE.COM
kadmin: modprinc -expire "2026-12-31" alice@EXAMPLE.COM
kadmin: modprinc -maxlife "12h" alice@EXAMPLE.COM
kadmin: quit
```

```bash
# Non-interactive
kadmin.local -q "addprinc alice"
kadmin -p admin/admin -q "listprincs"
```

### 13.6 Keytab Management

```bash
# Create keytab for a service
sudo ktadd -k /etc/krb5.keytab HTTP/server.example.com

# List keys in keytab
sudo klist -k /etc/krb5.keytab

# Test keytab authentication
kinit -k -t /etc/krb5.keytab HTTP/server.example.com
```

### 13.7 SSH with Kerberos

```bash
# /etc/ssh/sshd_config
GSSAPIAuthentication yes
GSSAPICleanupCredentials yes

# /etc/ssh/ssh_config
GSSAPIAuthentication yes
GSSAPIDelegateCredentials yes

# Then:
kinit alice@EXAMPLE.COM
ssh server.example.com  # No password!
```

### 13.8 NFS with Kerberos

```bash
# /etc/exports (on NFS server)
/export *(sec=krb5p,rw)

# Mount on client
mount -t nfs4 -o sec=krb5p server:/export /mnt
```

### 13.9 Kerberos Policies

```bash
# List policies
kadmin -q "list_policies"

# Create policy
kadmin -q "addpol users -minlength 8 -minclasses 3 -history 10"

# Apply policy to principal
kadmin -q "modprinc -policy users alice@EXAMPLE.COM"
```

---

## 🎯 What You Will Achieve

| Level | Focus | Key Skills |
|-------|-------|------------|
| **Level 1: Basic** | LDAP concepts, installation | Understanding DIT/DN/RDN, LDIF format, installing OpenLDAP |
| **Level 2: Intermediary** | Configuration, auth, TLS | OLC config, PAM/NSS integration, LDAP browser tools, SSSD setup, backup |
| **Level 3: Advanced** | Replication, Kerberos, FreeIPA | Syncrepl, 389 DS, Kerberos tickets, FreeIPA, protocol internals |

---

## 🛠️ Section 14: 15 Hands-On Practices

### ⭐ Level 1: Basic Practices

#### Practice 1: Install and Configure OpenLDAP

```bash
# Install
sudo apt update && sudo apt install -y slapd ldap-utils

# Reconfigure
sudo dpkg-reconfigure slapd
# Set: domain=example.com, org=Example Inc, backend=MDB

# Verify
systemctl status slapd
ldapsearch -x -H ldap://localhost -b dc=example,dc=com
```

### ⭐ Level 2: Intermediary Practices

#### Practice 2: Add Organizational Units and Users

Create `company.ldif`:

```ldif
dn: dc=example,dc=com
objectClass: dcObject
objectClass: organization
dc: example
o: Example Inc

dn: ou=People,dc=example,dc=com
objectClass: organizationalUnit
ou: People

dn: ou=Groups,dc=example,dc=com
objectClass: organizationalUnit
ou: Groups

dn: uid=alice,ou=People,dc=example,dc=com
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
cn: Alice Smith
sn: Smith
uid: alice
uidNumber: 10001
gidNumber: 10001
homeDirectory: /home/alice
loginShell: /bin/bash
userPassword: {SSHA}hash

dn: uid=bob,ou=People,dc=example,dc=com
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
cn: Bob Jones
sn: Jones
uid: bob
uidNumber: 10002
gidNumber: 10002
homeDirectory: /home/bob
loginShell: /bin/bash
userPassword: {SSHA}hash

dn: cn=developers,ou=Groups,dc=example,dc=com
objectClass: posixGroup
cn: developers
gidNumber: 10001
memberUid: alice
memberUid: bob
```

```bash
ldapadd -x -D cn=admin,dc=example,dc=com -W -f company.ldif
```

#### Practice 3: Search with ldapsearch

```bash
# All entries
ldapsearch -x -b dc=example,dc=com

# Only people
ldapsearch -x -b ou=People,dc=example,dc=com

# Filter by uid
ldapsearch -x -b dc=example,dc=com '(uid=alice)'

# Only cn and mail
ldapsearch -x -b dc=example,dc=com '(uid=alice)' cn mail

# Wildcard
ldapsearch -x -b dc=example,dc=com '(uid=a*)'

# Count results
ldapsearch -x -b dc=example,dc=com '(objectClass=posixAccount)' | grep -c "^dn:"
```

#### Practice 4: Bind as Different Users

```bash
# Bind as admin
ldapwhoami -x -D cn=admin,dc=example,dc=com -W

# Bind as alice
ldapwhoami -x -D uid=alice,ou=People,dc=example,dc=com -W

# Anonymous bind
ldapwhoami -x

# Compare what each can read
ldapsearch -x -b dc=example,dc=com '(uid=alice)' userPassword
# Anonymous: no access to userPassword
# Admin: sees password hash
```

#### Practice 5: Set Up PAM/LDAP Authentication

```bash
# Install modules
sudo apt install -y libnss-ldapd libpam-ldapd

# During config: server=ldap://localhost, base=dc=example,dc=com

# Verify nsswitch
grep ldap /etc/nsswitch.conf

# Test
getent passwd alice
getent group developers

# Create home directory and test login
sudo mkdir -p /home/alice
sudo chown alice:developers /home/alice
su - alice
```

#### Practice 6: Enable TLS on OpenLDAP

```bash
# Generate self-signed certs
sudo mkdir -p /etc/ldap/ssl
sudo openssl req -x509 -nodes -days 365 \
  -newkey rsa:2048 \
  -keyout /etc/ldap/ssl/ldap-key.pem \
  -out /etc/ldap/ssl/ldap-cert.pem \
  -subj "/CN=localhost"

# Set permissions
sudo chown -R openldap:openldap /etc/ldap/ssl
sudo chmod 600 /etc/ldap/ssl/ldap-key.pem

# Enable TLS in cn=config
cat > tls-enable.ldif << 'EOF'
dn: cn=config
changetype: modify
add: olcTLSCertificateFile
olcTLSCertificateFile: /etc/ldap/ssl/ldap-cert.pem
-
add: olcTLSKeyFile
olcTLSKeyFile: /etc/ldap/ssl/ldap-key.pem
-
add: olcTLSCACertificateFile
olcTLSCACertificateFile: /etc/ldap/ssl/ldap-cert.pem
EOF

ldapmodify -Y EXTERNAL -H ldapi:/// -f tls-enable.ldif

# Restart and test
sudo systemctl restart slapd

# Test StartTLS
LDAPTLS_REQCERT=never ldapsearch -x -H ldap://localhost -ZZ -b dc=example,dc=com

# Test LDAPS
LDAPTLS_REQCERT=never ldapsearch -x -H ldaps://localhost -b dc=example,dc=com
```

#### Practice 7: Configure SSSD for LDAP

```bash
# Stop nslcd (conflicts with SSSD)
sudo systemctl stop nslcd
sudo systemctl disable nslcd

# Install SSSD
sudo apt install -y sssd sssd-ldap libpam-sss libnss-sss

# Configure
sudo tee /etc/sssd/sssd.conf << 'EOF'
[sssd]
domains = example.com
services = nss, pam
config_file_version = 2

[domain/example.com]
id_provider = ldap
auth_provider = ldap
ldap_uri = ldap://localhost
ldap_search_base = dc=example,dc=com
cache_credentials = True
enumerate = True
EOF

sudo chmod 600 /etc/sssd/sssd.conf
sudo systemctl enable --now sssd

# Test
getent passwd alice
id alice
```

#### Practice 8: LDAP Backup and Restore

```bash
# Export all data to LDIF
sudo slapcat -l /backup/ldap-$(date +%Y%m%d).ldif

# Export specific database
sudo slapcat -n 1 -l /backup/example.ldif

# Export cn=config
sudo slapcat -n 0 -l /backup/config.ldif -F /etc/ldap/slapd.d/

# Restore (stop slapd first)
sudo systemctl stop slapd
sudo slapadd -l /backup/example.ldif -n 1
sudo chown -R openldap:openldap /var/lib/ldap/
sudo systemctl start slapd
```

#### Practice 9: Set Access Controls

```bash
cat > acl.ldif << 'EOF'
dn: olcDatabase={0}mdb,cn=config
changetype: modify
replace: olcAccess
olcAccess: to attrs=userPassword,shadowLastChange
  by self write
  by anonymous auth
  by dn.base="cn=admin,dc=example,dc=com" write
  by * none
olcAccess: to dn.base=""
  by * read
olcAccess: to *
  by self write
  by dn.base="cn=admin,dc=example,dc=com" write
  by users read
  by * none
EOF

ldapmodify -Y EXTERNAL -H ldapi:/// -f acl.ldif
```

### ⭐ Level 3: Advanced Practices

#### Practice 10: Set Up Syncrepl Replication

On **Server A** (192.168.1.10 — provider):

```bash
# Add syncprov overlay
cat > setup-syncprov.ldif << 'EOF'
dn: cn=module{0},cn=config
changetype: modify
add: olcModuleLoad
olcModuleLoad: syncprov

dn: olcOverlay=syncprov,olcDatabase={0}mdb,cn=config
changetype: add
objectClass: olcOverlayConfig
objectClass: olcSyncProvConfig
olcOverlay: syncprov
olcSpCheckpoint: 100 10
olcSpSessionLog: 100
EOF

ldapmodify -Y EXTERNAL -H ldapi:/// -f setup-syncprov.ldif
```

On **Server B** (192.168.1.11 — consumer):

```bash
# Install slapd (empty database)
sudo apt install -y slapd ldap-utils
sudo dpkg-reconfigure slapd
# Same domain: example.com

# Configure as consumer
cat > setup-consumer.ldif << 'EOF'
dn: olcDatabase={0}mdb,cn=config
changetype: modify
replace: olcSyncrepl
olcSyncrepl: rid=001 provider=ldap://192.168.1.10:389 \
  binddn="cn=admin,dc=example,dc=com" \
  credentials="yourpassword" \
  searchbase="dc=example,dc=com" \
  schemachecking=on \
  type=refreshAndPersist \
  retry="60 +"
EOF

ldapmodify -Y EXTERNAL -H ldapi:/// -f setup-consumer.ldif

# Verify
ldapsearch -x -H ldap://localhost -b dc=example,dc=com
# Should show same entries as provider
```

#### Practice 11: Kerberos kinit/klist

```bash
# Install Kerberos client
sudo apt install -y krb5-user
# Set realm: EXAMPLE.COM, KDC: localhost

# If no KDC available, use FreeIPA or install a test KDC:
sudo apt install -y krb5-kdc krb5-admin-server

# Create realm
sudo krb5_newrealm

# Add principal
sudo kadmin.local -q "addprinc alice"

# Test
kinit alice@EXAMPLE.COM
klist
kdestroy
```

#### Practice 12: Password Policy Overlay

```bash
cat > ppolicy.ldif << 'EOF'
dn: cn=module{0},cn=config
changetype: modify
add: olcModuleLoad
olcModuleLoad: ppolicy

dn: olcOverlay=ppolicy,olcDatabase={0}mdb,cn=config
changetype: add
objectClass: olcOverlayConfig
objectClass: olcPPolicyConfig
olcOverlay: ppolicy
olcPPolicyDefault: cn=default,ou=Policies,dc=example,dc=com
olcPPolicyHashCleartext: TRUE
olcPPolicyUseLockout: TRUE
EOF

ldapmodify -Y EXTERNAL -H ldapi:/// -f ppolicy.ldif

# Create password policy entry
cat > default-policy.ldif << 'EOF'
dn: ou=Policies,dc=example,dc=com
objectClass: organizationalUnit
ou: Policies

dn: cn=default,ou=Policies,dc=example,dc=com
objectClass: pwdPolicy
objectClass: person
cn: default
sn: default
pwdAttribute: userPassword
pwdMinLength: 8
pwdMaxAge: 7776000
pwdInHistory: 5
pwdMaxFailure: 5
pwdLockout: TRUE
pwdLockoutDuration: 900
pwdGraceAuthNLimit: 3
EOF

ldapadd -x -D cn=admin,dc=example,dc=com -W -f default-policy.ldif
```

#### Practice 13: MemberOf Overlay (Reverse Group Membership)

```bash
cat > memberof.ldif << 'EOF'
dn: cn=module{0},cn=config
changetype: modify
add: olcModuleLoad
olcModuleLoad: memberof

dn: olcOverlay=memberof,olcDatabase={0}mdb,cn=config
changetype: add
objectClass: olcOverlayConfig
objectClass: olcMemberOf
olcOverlay: memberof
olcMemberOfDangling: ignore
olcMemberOfRefInt: TRUE
EOF

ldapmodify -Y EXTERNAL -H ldapi:/// -f memberof.ldif

# Test — users now have memberOf attribute
ldapsearch -x -b dc=example,dc=com '(uid=alice)' memberOf
```

#### Practice 14: LDAP Schema Customization

Add a custom `employeeType` attribute:

```bash
cat > custom-schema.ldif << 'EOF'
dn: cn=custom,cn=schema,cn=config
changetype: add
objectClass: olcSchemaConfig
cn: custom
olcAttributeTypes: ( 1.3.6.1.4.1.99999.1.1 NAME 'employeeType' \
  SYNTAX 1.3.6.1.4.1.1466.115.121.1.15 SINGLE-VALUE )
olcObjectClasses: ( 1.3.6.1.4.1.99999.2.1 NAME 'customEmployee' \
  SUP inetOrgPerson AUXILIARY MAY ( employeeType ) )
EOF

ldapadd -Y EXTERNAL -H ldapi:/// -f custom-schema.ldif

# Now add employeeType to alice
cat > add-emp-type.ldif << 'EOF'
dn: uid=alice,ou=People,dc=example,dc=com
changetype: modify
add: objectClass
objectClass: customEmployee
-
add: employeeType
employeeType: full-time
EOF

ldapmodify -x -D cn=admin,dc=example,dc=com -W -f add-emp-type.ldif
```

#### Practice 15: Real-World Integration

Build a complete LDAP authentication infrastructure:

```bash
# ┌─────────────────────────────────────────────────────────────┐
# │  REAL-WORLD INTEGRATION CHECKLIST                          │
# │                                                             │
# │  [✓] OpenLDAP provider installed and configured             │
# │  [✓] Organizational units (People, Groups, Services) added  │
# │  [✓] Users and groups added with posixAccount attributes    │
# │  [✓] TLS enabled with self-signed CA                       │
# │  [✓] Client 1: PAM/NSS LDAP authentication via nslcd       │
# │  [✓] Client 2: SSSD with LDAP provider and caching         │
# │  [✓] Replication consumer set up for HA                    │
# │  [✓] Password policy enforced                              │
# │  [✓] Backup script scheduled via cron                      │
# │  [✓] Monitoring — slapd logs sent to centralized logging   │
# │  [✓] Firewall — only port 389/636 open to clients          │
# └─────────────────────────────────────────────────────────────┘
```

**Reference architecture:**

```
                              Internet
                                  │
                            [Firewall :389/636]
                                  │
                    ┌─────────────┴─────────────┐
                    │                           │
            LDAP Provider                LDAP Consumer
            (192.168.1.10)              (192.168.1.11)
                    │                           │
                    └─────────────┬─────────────┘
                                  │
                    ┌─────────────┼─────────────┐
                    │             │             │
              Web Server    Mail Server   Dev Laptops
              (SSSD)        (nslcd)       (SSSD)
```

**Cron backup script:**

```bash
#!/bin/bash
# /usr/local/bin/ldap-backup.sh
BACKUP_DIR="/backup/ldap"
DATE=$(date +%Y%m%d_%H%M)
mkdir -p $BACKUP_DIR

# Export LDAP data
slapcat -l "$BACKUP_DIR/ldap-$DATE.ldif"

# Export cn=config
slapcat -n 0 -l "$BACKUP_DIR/config-$DATE.ldif"

# Compress
gzip "$BACKUP_DIR/ldap-$DATE.ldif"
gzip "$BACKUP_DIR/config-$DATE.ldif"

# Keep only last 30 days
find $BACKUP_DIR -name "*.gz" -mtime +30 -delete
```

---

## 🧠 Section 15: Deep Understanding

### 15.1 How OpenLDAP Backend Works

**MDB** (Memory-Mapped Database) is the modern backend for OpenLDAP. Previous backends were **BDB** (Berkeley DB) and **HDB** (Hierarchical BDB). All three are key-value stores, but MDB is vastly superior.

| Feature | BDB | HDB | MDB |
|---------|-----|-----|-----|
| Hierarchy | Flat | Nested entries | Nested entries |
| Performance | Slow under write load | Better | **Excellent** |
| Corruption | Fragile | Less fragile | **Crash-safe** (read-only memory map) |
| Database size | Limited | Limited | **Terabytes** (mmap) |
| Concurrent readers | Configurable | Configurable | **Unlimited** (MVCC) |
| Configuration | `olcDbMode` | `olcDbMode` | `olcDbMaxSize` |
| Default in | OpenLDAP < 2.4 | Never | OpenLDAP ≥ 2.4.40 |

MDB uses **memory-mapped files** (mmap). The entire database is mapped into virtual memory. This means:

- Multiple processes can read the same data without locking
- Reads never block writes (Multi-Version Concurrency Control)
- On crash, the database is always consistent (no journal recovery)
- Only explicit `fsync` on writes

Backend file layout (`/var/lib/ldap/`):

```
data.mdb       — The main database (all entries, all attributes)
lock.mdb       — Lock file (tiny, for write serialization)
alock.mdb      — Alarm lock
cn=accesslog/  — Access log database (for delta-syncrepl)
```

### 15.2 How PAM Modules Stack

PAM uses a **stack** of modules. Each module returns success or failure. The control flags determine behavior:

| Flag | Meaning |
|------|---------|
| `required` | Must succeed. If fails, continue checking other modules but deny at end. |
| `requisite` | Must succeed. If fails, **immediately** deny (skip remaining modules). |
| `sufficient` | If succeeds, **immediately** accept (skip remaining). If fails, continue. |
| `optional` | Not critical. Result used only if no other module determined outcome. |
| `include` | Include another PAM config file. |
| `substack` | Like include but with its own stack. |

**Typical PAM auth stack for LDAP:**

```
auth  [success=2 default=ignore]  pam_unix.so nullok_secure
auth  [success=1 default=ignore]  pam_ldap.so use_first_pass
auth  requisite                   pam_deny.so
auth  required                    pam_permit.so
```

**Flow for `su - alice`:**

```
1. pam_unix.so          → checks /etc/shadow first (local users)
                           → if alice not in /etc/shadow, ignore
2. pam_ldap.so          → prompts for password, sends to LDAP
                           → if password correct, success=1 skips to pam_permit
                           → if password wrong, goes to next
3. pam_deny.so          → if we get here, authentication failed
4. pam_permit.so        → should not be reached if denied
```

**For SSSD:**

```
auth  sufficient        pam_sss.so forward_pass
auth  required          pam_unix.so nullok_secure use_first_pass
```

The `pam_sss.so` module checks SSSD's cache first for fast response.

### 15.3 How NSS Calls nss_ldap

NSS is configured in `/etc/nsswitch.conf`. Each database (passwd, group, shadow) has a list of sources:

```
passwd:  compat systemd ldap
```

When `getent passwd alice` runs:

1. **glibc** checks `nsswitch.conf` → sources are `compat`, `systemd`, `ldap`
2. **compat** (nss_compat.so) → checks `/etc/passwd` for local users
3. **systemd** (nss_systemd.so) → checks systemd user database (DynamicUser)
4. **ldap** (nss_ldap.so) → calls `nslcd` via Unix socket `/var/run/nslcd/socket`
5. **nslcd** → connects to LDAP server, performs search `(&(objectClass=posixAccount)(uid=alice))`
6. Returns result → glibc formats as `struct passwd` → application gets user entry

For **SSSD**, the source is `sss`:

```
passwd:  compat systemd sss
```

Here, `nss_sss.so` talks to SSSD via D-Bus, not via nslcd.

### 15.4 The LDAP Protocol

LDAP is an **application-layer protocol** running over TCP (port 389) or TLS (port 636). Operations use **ASN.1/BER** encoding.

**Core LDAP Operations:**

| Operation | Code | Purpose |
|-----------|------|---------|
| Bind | 0x60 | Authenticate (prove identity) |
| Search | 0x63 | Query the directory |
| Compare | 0x6E | Test if an attribute equals a value |
| Add | 0x68 | Add a new entry |
| Delete | 0x6A | Delete an entry |
| Modify | 0x66 | Change attribute values |
| ModDN | 0x6C | Rename or move an entry |
| Unbind | 0x42 | Close the connection gracefully |
| Abandon | 0x50 | Cancel a pending operation |
| Extended Operation | 0x77 | Custom operations (StartTLS, WhoAmI, Password Modify) |

**The Bind Operation (Simplified):**

```
Client:                              Server:
  |                                     |
  |---- Bind Request ------------------>|
  |    version = 3                      |
  |    name = "cn=admin,dc=example,dc=com"
  |    authentication = simple          |
  |    credentials = "secret"           |
  |                                     |
  |<--- Bind Response ------------------|
  |    result code = 0 (success)        |
  |                                     |
```

**The Search Operation (Simplified):**

```
Client:                              Server:
  |                                     |
  |---- Search Request ---------------->|
  |    baseObject = "dc=example,dc=com" |
  |    scope = wholeSubtree             |
  |    derefAliases = neverDerefAliases |
  |    sizeLimit = 0 (no limit)         |
  |    timeLimit = 0 (no limit)         |
  |    filter = "(uid=alice)"           |
  |    attributes = [ "cn", "mail" ]    |
  |                                     |
  |<--- Search Result Entry ------------|
  |    dn: uid=alice,ou=People,...      |
  |    cn: Alice Smith                  |
  |    mail: alice@example.com          |
  |                                     |
  |<--- Search Result Done -------------|
  |    result code = 0                  |
  |    matched entries = 1              |
  |                                     |
```

**LDAP Result Codes:**

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Operations Error |
| 2 | Protocol Error |
| 10 | Referral |
| 13 | Confidentiality Required |
| 14 | SASL Bind In Progress |
| 16 | No Such Attribute |
| 17 | Undefined Attribute Type |
| 20 | Attribute or Value Exists |
| 32 | No Such Object |
| 33 | Alias Problem |
| 34 | Invalid DN Syntax |
| 48 | Inappropriate Authentication |
| 49 | **Invalid Credentials** — wrong password! |
| 50 | Insufficient Access Rights |
| 51 | Busy |
| 52 | Unavailable |
| 53 | Unwilling to Perform |
| 80 | Other (server-specific error) |

### 15.5 ASN.1 / BER Encoding

LDAP is encoded using **BER** (Basic Encoding Rules) for **ASN.1** (Abstract Syntax Notation One).

An ASN.1 value is encoded as **TLV** (Type-Length-Value):

```
+--------+--------+--------+
|  TYPE  | LENGTH | VALUE  |
|  1-4B  | 1-126B | var.   |
+--------+--------+--------+
```

For example, the LDAP Bind Request:

```
Tag 0x60 (APPLICATION 0 — Bind Request)
Length = 30 bytes
  Tag 0x02 (INTEGER)
  Length = 1
  Value = 03 (LDAP version 3)

  Tag 0x04 (OCTET STRING)
  Length = 28
  Value = "cn=admin,dc=example,dc=com"

  Tag 0x80 (CONTEXT-SPECIFIC 0 — simple auth)
  Length = 6
  Value = "secret"
```

You can see BER encoding with a packet capture:

```bash
# Capture LDAP traffic
sudo tcpdump -i any -X port 389
# The hex contains the BER-encoded LDAP operations
```

### 15.6 LDAP Referrals and Chaining

When an LDAP server does not hold the requested data, it can return a **referral** (code 10):

```bash
ldapsearch -x -b dc=other,dc=com '(uid=alice)'
# Result: Referral (10)
# Matched DN: dc=other,dc=com
# Referral: ldap://other-server.example.com/dc=other,dc=com
```

Clients can follow referrals automatically:

```bash
ldapsearch -x -b dc=example,dc=com -E 'chaining=resolve' '(uid=alice)'
```

---

## 📋 Section 16: Command Reference

### ⭐ Level 1: Basic Commands

#### 16.1 OpenLDAP Server Commands

| Command | Description |
|---------|-------------|
| `slapd -d 256` | Start slapd in debug mode (stats logging) |
| `slapd -d -1` | Start slapd with all debug flags |
| `slapcat` | Export LDAP database to LDIF |
| `slapadd` | Import LDIF into LDAP database |
| `slapindex` | Rebuild indices |
| `slapauth` | Test access controls |
| `slaptest -u` | Test configuration validity |
| `slappasswd -s secret` | Generate SSHA password hash |
| `slapd -h "ldap:/// ldaps:/// ldapi:///"` | Listen on all protocols |

### ⭐ Level 2: Intermediary Commands

#### 16.2 LDAP Client Commands

| Command | Description | Example |
|---------|-------------|---------|
| `ldapsearch` | Search directory | `ldapsearch -x -H ldap://host -b dc=example,dc=com '(uid=alice)'` |
| `ldapadd` | Add entries from LDIF | `ldapadd -x -D cn=admin,dc=example,dc=com -W -f file.ldif` |
| `ldapmodify` | Modify entries | `ldapmodify -x -D cn=admin,dc=example,dc=com -W -f mod.ldif` |
| `ldapdelete` | Delete entries | `ldapdelete -x -D cn=admin,dc=example,dc=com -W 'uid=bob,dc=example,dc=com'` |
| `ldapwhoami` | Show bound DN | `ldapwhoami -x -D cn=admin,dc=example,dc=com -W` |
| `ldapcompare` | Test attribute value | `ldapcompare -x 'dn' 'attr:value'` |
| `ldappasswd` | Change password | `ldappasswd -x -D cn=admin,dc=example,dc=com -W -S` |
| `ldapurl` | Compose LDAP URLs | `ldapurl -H ldap://server/dc=example,dc=com??sub?(uid=a*)` |

#### 16.3 LDAP Search Options

| Option | Purpose |
|--------|---------|
| `-x` | Simple authentication (not SASL) |
| `-H ldap://host:port` | LDAP server URI |
| `-D binddn` | Bind DN for authentication |
| `-W` | Prompt for password |
| `-w password` | Password on command line (insecure) |
| `-b basedn` | Base DN for search |
| `-s scope` | Scope: base, one, sub |
| `-f file` | Read filter from file |
| `-l seconds` | Time limit |
| `-z size` | Size limit |
| `-ZZ` | Require StartTLS |
| `-Z` | Try StartTLS (optional) |
| `-Y EXTERNAL` | SASL EXTERNAL (for cn=config via ldapi) |

#### 16.4 SSSD Commands

| Command | Description |
|---------|-------------|
| `sssctl domain-status example.com` | Check domain health |
| `sssctl cache-remove` | Clear SSSD cache |
| `sssctl debug-level 9` | Set maximum debug level |
| `sssctl ldap-test` | Test LDAP connectivity |
| `sssctl user-checks alice` | Show user authentication path |
| `sssd --genconf` | Generate default configuration |

### ⭐ Level 3: Advanced Commands

#### 16.5 Kerberos Commands

| Command | Description | Example |
|---------|-------------|---------|
| `kinit` | Get TGT | `kinit alice@EXAMPLE.COM` |
| `klist` | List tickets | `klist -e -A` |
| `kdestroy` | Destroy tickets | `kdestroy -A` |
| `kvno` | Get service ticket | `kvno host/server.example.com` |
| `kadmin.local` | Admin (local) | `kadmin.local -q "addprinc alice"` |
| `kadmin` | Admin (remote) | `kadmin -p admin/admin -q "listprincs"` |
| `ktadd` | Export keytab | `kadmin.local -q "ktadd -k /etc/krb5.keytab host/www"` |
| `ktutil` | Manage keytabs | `ktutil` (interactive) |
| `kpasswd` | Change password | `kpasswd alice@EXAMPLE.COM` |

#### 16.6 389 DS Commands

| Command | Description |
|---------|-------------|
| `dsctl instance status` | Instance status |
| `dsctl instance restart` | Restart instance |
| `dsconf instance backend list` | List backends |
| `dsconf instance user create` | Create user |
| `dsconf instance plugin enable` | Enable plugin |
| `dsidm instance user list` | List users |

---

## 📖 Section 17: What's Coming in Part 42

**Part 42: DNS Server Administration (BIND)** — The Domain Name System is the backbone of the internet and every internal network. You will learn:

- How DNS works (recursive vs. authoritative, root hints, TLDs)
- BIND installation and configuration (named, named.conf)
- Zone files (SOA, A, AAAA, CNAME, MX, TXT, SRV records)
- Forward and reverse zones
- Master/slave zone transfers (AXFR, IXFR)
- DNSSEC (signing zones, trust anchors)
- split-DNS (internal vs. external views)
- Troubleshooting with dig, nslookup, host, delv
- Dynamic DNS updates with nsupdate
- Performance tuning and security (ACLs, rate limiting, rndc)

```
Previous → Part 40: Databases
Next → Part 42: DNS Server Administration (BIND)
```

---

## ✅ Section 18: Self-Test

**Instructions:** Answer each question. Score 12/15 or higher before proceeding to Part 42.

### Questions

**Q1:** What does LDAP stand for, and what is its primary purpose?

**Q2:** What is the difference between a DN and an RDN? Give an example.

**Q3:** Write the LDIF to add a user `uid=charlie,ou=People,dc=example,dc=com` with objectClass `inetOrgPerson` and `posixAccount`. Charlie Brown, uid=10003, gid=10003, /home/charlie, /bin/bash.

**Q4:** What is the OLC (Online Configuration) in OpenLDAP, and why is it preferred over editing slapd.conf?

**Q5:** You run `ldapsearch -x -b dc=example,dc=com '(uid=alice)'` and get "No such object (32)." What are the three most likely causes?

**Q6:** What is the difference between PAM and NSS? Which controls authentication and which controls lookups?

**Q7:** You installed `libnss-ldapd` on a client but `getent passwd alice` returns nothing. List three debugging steps.

**Q8:** What does the `-ZZ` flag in `ldapsearch -ZZ` do?

**Q9:** In Kerberos, what is a TGT? What is the difference between the AS and the TGS?

**Q10:** What is SSSD and what advantage does it have over direct PAM LDAP (`libpam-ldapd`)?

**Q11:** What is the difference between `type=refreshAndPersist` and `type=refreshOnly` in OpenLDAP replication?

**Q12:** FreeIPA combines which four major components?

**Q13:** An LDAP Bind Request fails with result code 49. What does this mean? How would you troubleshoot?

**Q14:** What is the `memberOf` overlay and why would you use it?

**Q15:** In the PAM auth stack, what is the difference between `required` and `sufficient`?

### Answer Key

**A1:** Lightweight Directory Access Protocol. Directory service for centralized user/group storage, address books, authentication, and configuration.

**A2:** DN is the full path (e.g. `uid=alice,ou=People,dc=example,dc=com`). RDN is the local component (e.g. `uid=alice`). The RDN is the first component of the DN.

**A3:**
```ldif
dn: uid=charlie,ou=People,dc=example,dc=com
objectClass: inetOrgPerson
objectClass: posixAccount
cn: Charlie Brown
sn: Brown
uid: charlie
uidNumber: 10003
gidNumber: 10003
homeDirectory: /home/charlie
loginShell: /bin/bash
```

**A4:** OLC stores config as LDAP entries under `cn=config`, modifiable with `ldapmodify` while slapd runs. Preferred because: no restart needed, validated on load, can be replicated, version-controlled via LDIF.

**A5:** (1) Wrong base DN — `dc=example,dc=com` does not exist on server. (2) No permissions — anonymous bind not allowed to search. (3) Server unreachable — wrong host/port, firewall blocking 389.

**A6:** **PAM** controls authentication (password verification, account expiry, session setup). **NSS** controls lookups (`getent passwd`, `getent group`, etc.). PAM authenticates; NSS retrieves identity data.

**A7:** (1) Check `nslcd` is running: `systemctl status nslcd`. (2) Check `/etc/nsswitch.conf` has `ldap` in `passwd` line. (3) Test connectivity: `ldapsearch -x -H ldap://server -b dc=example,dc=com '(uid=alice)'`.

**A8:** Require StartTLS — the client will refuse to connect if the server does not upgrade to TLS. Single `-Z` means "try TLS but proceed without if unavailable."

**A9:** **TGT** (Ticket Granting Ticket) is a ticket proving the user authenticated successfully. **AS** (Authentication Service) issues TGTs after verifying password. **TGS** (Ticket Granting Service) issues service tickets using the TGT.

**A10:** SSSD caches credentials locally, allowing offline authentication (network goes down but users still log in). It also provides faster responses (cache hit vs. network query) and supports multiple identity providers.

**A11:** `refreshAndPersist` — consumer pulls full data, then stays connected for real-time updates. `refreshOnly` — consumer polls periodically (no persistent connection, higher latency).

**A12:** 389 Directory Server (LDAP) + MIT Kerberos + BIND (DNS) + Dogtag Certificate System (CA) + NTP.

**A13:** **Invalid Credentials** — the bind DN or password is wrong. Troubleshoot: (1) Verify the DN is correct (`dn:` in LDIF matches). (2) Check the password with `slappasswd -v`. (3) Test with `ldapwhoami -x -D ... -W`. (4) Check server logs: `journalctl -u slapd`.

**A14:** The memberOf overlay automatically populates a `memberOf` attribute on user entries listing which groups they belong to. Without it, you must search groups for `memberUid=alice`. It makes "what groups is alice in?" a single lookup instead of a subtree search.

**A15:** `required` — module must succeed; if it fails, continue checking other modules but deny at end. `sufficient` — if module succeeds, immediately accept authentication (skip remaining modules). If it fails, continue checking.

### Scoring

| Score | Result |
|-------|--------|
| **15/15** | Perfect — you are ready for DNS administration |
| **12–14/15** | Strong understanding — proceed to Part 42 |
| **9–11/15** | Review the sections you missed — you are close |
| **< 9/15** | Re-read Part 41 and practice with the 15 hands-on exercises |

**Score:** ___/15 correct = ready for Part 42.

---

## 📚 Quick Reference Cards

### LDIF Quick Reference

```
# Add entry
dn: uid=alice,ou=People,dc=example,dc=com
changetype: add (default for ldapadd)
objectClass: posixAccount
uid: alice

# Modify — add attribute
dn: uid=alice,ou=People,dc=example,dc=com
changetype: modify
add: telephoneNumber
telephoneNumber: +1-555-1234

# Modify — replace attribute
changetype: modify
replace: mail
mail: alice.new@example.com

# Modify — delete attribute
changetype: modify
delete: telephoneNumber

# Delete entry
dn: uid=alice,ou=People,dc=example,dc=com
changetype: delete

# Rename (modrdn)
dn: uid=alice,ou=People,dc=example,dc=com
changetype: modrdn
newrdn: uid=alice.smith
deleteoldrdn: 1
```

### Common LDAP Filters

| Purpose | Filter |
|---------|--------|
| All people | `(objectClass=posixAccount)` |
| User by UID | `(uid=alice)` |
| Group by name | `(cn=developers)` |
| Users in group | `(&(objectClass=posixAccount)(memberOf=cn=developers,ou=Groups,dc=example,dc=com))` |
| Active users | `(&(objectClass=posixAccount)(!(shadowMax=0)))` |
| Users with UID > 10000 | `(&(objectClass=posixAccount)(uidNumber>=10000))` |
| Users with no shell | `(&(objectClass=posixAccount)(loginShell=/bin/false))` |

### Port Reference

| Port | Protocol | Service |
|------|----------|---------|
| 389/tcp | LDAP | Standard LDAP |
| 636/tcp | LDAPS | LDAP over TLS |
| 3268/tcp | Global Catalog | AD Global Catalog (LDAP) |
| 3269/tcp | Global Catalog SSL | AD Global Catalog (LDAPS) |
| 88/tcp, 88/udp | Kerberos | KDC |
| 749/tcp | kadmin | Kerberos admin |
| 464/tcp, 464/udp | kpasswd | Kerberos password change |
| 123/udp | NTP | Network Time Protocol |

---

*Previous → Part 40: Databases*
*Next → Part 42: DNS Server Administration (BIND)*

[← Previous](part40.md) | [Next →](part42.md)
