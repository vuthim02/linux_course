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





[← Previous](09-section-7-ldap-over-tls.md) | [↑ Index](index.md) | [Next →](11-level-3-advanced-ldap-internals.md)
