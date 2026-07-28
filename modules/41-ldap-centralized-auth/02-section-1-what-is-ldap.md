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





[← Previous](01-level-1-basic-understanding-ldap.md) | [↑ Index](index.md) | [Next →](03-section-2-openldap-installation.md)
