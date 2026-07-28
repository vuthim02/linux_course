## ⭐ Level 1: Basic — Understanding LDAP Concepts

![LDAP Directory Information Tree — hierarchical entry structure](https://upload.wikimedia.org/wikipedia/commons/3/3e/Datenstruktur.png)

> **Level 1 Goal:** Understand what LDAP is, its core concepts (DIT, DN, RDN, objectClass), the LDIF format, and how to install OpenLDAP.

### What You'll Cover
- What LDAP is and how it differs from databases like SQL
- The Directory Information Tree (DIT) structure
- Distinguished Names (DN), Relative DNs (RDN), and attributes
- Object classes and the schema system
- The LDIF (LDAP Data Interchange Format) for reading/writing entries
- Installing OpenLDAP (`slapd`) on Ubuntu/Debian

LDAP (Lightweight Directory Access Protocol) is a protocol for reading and modifying directory information — user accounts, groups, certificates, and organizational data. Unlike SQL databases optimized for transactions, LDAP is optimized for read-heavy, hierarchical data.

At this level you will learn:

- **LDAP vs SQL**: LDAP stores data in a tree (DIT), not tables. Data is organized by attributes (like columns) and object classes (like schemas). Reads are extremely fast; writes are less frequent. LDAP is optimized for authentication lookups and organizational data.
- **DIT structure**: The root is the base DN (e.g., `dc=example,dc=com`). Each entry is a node: `cn=admin,dc=example,dc=com`. Organizational Units (`ou=Users`) group entries. The tree structure mirrors organizational hierarchy.
- **DN and RDN**: A Distinguished Name (DN) is the full path to an entry: `cn=John Doe,ou=Users,dc=example,dc=com`. The Relative DN (RDN) is the unique part: `cn=John Doe`. Think of DN as a file path and RDN as a filename.
- **Object classes**: Every entry belongs to at least one object class (e.g., `inetOrgPerson`, `posixAccount`). Object classes define which attributes are required and which are optional. The schema system enforces data integrity.
- **LDIF**: The standard format for LDAP data. An LDIF entry looks like:
  ```
  dn: cn=John Doe,ou=Users,dc=example,dc=com
  objectClass: inetOrgPerson
  cn: John Doe
  mail: john@example.com
  ```
  LDIF is used for importing, exporting, and modifying LDAP data.


[↑ Index](index.md) | [Next →](02-section-1-what-is-ldap.md)
