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



---

[← Previous](06-section-4-ldap-data-interchange.md) | [↑ Index](index.md) | [Next →](08-section-6-ldap-authentication-pam.md)
