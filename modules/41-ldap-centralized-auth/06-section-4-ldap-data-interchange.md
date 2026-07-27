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



---

[← Previous](05-section-3-openldap-configuration-cnconfig.md) | [↑ Index](index.md) | [Next →](07-section-5-ldap-schemas.md)
