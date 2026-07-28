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





[← Previous](08-section-6-ldap-authentication-pam.md) | [↑ Index](index.md) | [Next →](10-section-8-ldap-browser-tools.md)
