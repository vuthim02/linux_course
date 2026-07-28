## 6. LDAP Integration

### LDAP Basics

LDAP (Lightweight Directory Access Protocol) stores data in a hierarchical tree:

```
                    dc=example,dc=com
                           │
            ┌──────────────┼──────────────┐
            │              │              │
     ou=People      ou=Groups      ou=Service
            │              │              │
     ┌──────┼──────┐  ┌───┼────┐    cn=readonly
     │      │      │  │   │    │    cn=ldap-admin
   uid=john uid=jane uid=bob  cn=admins  cn=users
```

### Key LDAP Attributes

```
┌────────────────────────────────────────────────────────┐
│  OBJECTCLASS: inetOrgPerson / posixAccount              │
├────────────────────────────────────────────────────────┤
│  uid              = john                                 │
│  cn               = John Smith                           │
│  sn               = Smith                                │
│  givenName        = John                                 │
│  mail             = john@example.com                     │
│  uidNumber        = 10001                                │
│  gidNumber        = 10000                                │
│  homeDirectory    = /home/john                           │
│  loginShell       = /bin/bash                            │
│  userPassword     = {SSHA}hashed_password               │
│  memberOf         = cn=admins,ou=Groups,dc=example,dc=com│
│  sshPublicKey     = ssh-rsa AAAA... user@example.com     │
│  shadowLastChange = 20265                                │
│  shadowMin        = 7                                    │
│  shadowMax        = 90                                   │
│  shadowWarning    = 14                                   │
└────────────────────────────────────────────────────────┘
```

### Setting Up OpenLDAP Server (Quick Reference)

```bash
# Install OpenLDAP (RHEL/Fedora)
sudo dnf install openldap-servers openldap-clients

# Install OpenLDAP (Debian/Ubuntu)
sudo apt install slapd ldap-utils

# Start and enable
sudo systemctl enable --now slapd

# Set admin password
sudo ldapmodify -Y EXTERNAL -H ldapi:/// <<EOF
dn: olcDatabase={0}config,cn=config
changetype: modify
add: olcRootPW
olcRootPW: {SSHA}$(slappasswd -s "AdminP@ss123")
EOF
```

```bash
# Import basic schemas
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif
```

```bash
# Create base DN
cat <<EOF | sudo ldapadd -Y EXTERNAL -H ldapi:/// 
dn: dc=example,dc=com
objectClass: top
objectClass: dcObject
objectClass: organization
o: Example Organization
dc: example

dn: ou=People,dc=example,dc=com
objectClass: organizationalUnit
ou: People

dn: ou=Groups,dc=example,dc=com
objectClass: organizationalUnit
ou: Groups
EOF
```

### LDAP over TLS (ldaps://)

```bash
# Generate certificate (or use Let's Encrypt)
sudo openssl req -new -x509 -nodes -days 365 \
  -keyout /etc/openldap/certs/ldap.key \
  -out /etc/openldap/certs/ldap.crt \
  -subj "/CN=ldap.example.com"

# Configure slapd to use TLS
cat <<EOF | sudo ldapmodify -Y EXTERNAL -H ldapi:///
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcTLSCACertificateFile
olcTLSCACertificateFile: /etc/openldap/certs/ca.crt
-
replace: olcTLSCertificateFile
olcTLSCertificateFile: /etc/openldap/certs/ldap.crt
-
replace: olcTLSCertificateKeyFile
olcTLSCertificateKeyFile: /etc/openldap/certs/ldap.key
EOF

# Enable ldaps:// in /etc/sysconfig/slapd
sudo sed -i 's|SLAPD_URLS="ldapi:/// ldap:///"|SLAPD_URLS="ldapi:/// ldaps:///"|' /etc/sysconfig/slapd
sudo systemctl restart slapd
```

### Adding Users to LDAP

```bash
# Add a user (using LDIF)
cat <<EOF | sudo ldapadd -x -D "cn=admin,dc=example,dc=com" -W
dn: uid=john,ou=People,dc=example,dc=com
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
uid: john
cn: John Smith
sn: Smith
givenName: John
mail: john@example.com
uidNumber: 10001
gidNumber: 10000
homeDirectory: /home/john
loginShell: /bin/bash
userPassword: {SSHA}$(slappasswd -s "temp123")
shadowLastChange: 0
shadowMin: 7
shadowMax: 90
shadowWarning: 14
EOF
```

> 🔍 **Reverse Engineering Insight:** When SSSD queries LDAP, it doesn't use `ldapsearch` — it uses the `libldap` C library directly. The LDAP filter it generates depends on `ldap_user_object_class` and `ldap_user_name` in `sssd.conf`. If these are wrong, you'll see zero results even though LDAP itself works fine.





[← Previous](06-5-sssd-architecture.md) | [↑ Index](index.md) | [Next →](08-7-authselect-managing-pam-profiles.md)
