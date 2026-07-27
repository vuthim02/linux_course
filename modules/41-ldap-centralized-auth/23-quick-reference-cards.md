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


---

[← Previous](22-section-18-self-test.md) | [↑ Index](index.md)
