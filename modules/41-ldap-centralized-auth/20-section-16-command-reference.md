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



---

[← Previous](19-section-15-deep-understanding.md) | [↑ Index](index.md) | [Next →](21-section-17-whats-coming-in.md)
