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





[← Previous](17-what-you-will-achieve.md) | [↑ Index](index.md) | [Next →](19-section-15-deep-understanding.md)
