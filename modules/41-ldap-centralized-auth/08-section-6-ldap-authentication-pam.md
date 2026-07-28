## 🔐 Section 6: LDAP Authentication (PAM and NSS)

### 6.1 The Authentication Stack

```
Application (login, ssh, su, sudo)
        │
        ▼
    ┌─────┐
    │ PAM │  Pluggable Authentication Modules
    └─────┘
        │
        ▼
    ┌─────┐
    │ NSS │  Name Service Switch
    └─────┘
        │
        ▼
    ┌──────┐
    │ nslcd│  LDAP client daemon → LDAP server
    └──────┘
```

### 6.2 PAM (Pluggable Authentication Modules)

PAM controls **authentication** (proving who you are). Config files are in `/etc/pam.d/`.

Three key files:

| File | Controls |
|------|----------|
| `common-auth` | Authentication process (password prompts) |
| `common-account` | Account management (account expiry, access times) |
| `common-password` | Password changes |
| `common-session` | Session setup (home dir creation, mounts) |

### 6.3 NSS (Name Service Switch)

NSS controls **lookup** (getting user/group info). Config file is `/etc/nsswitch.conf`.

```
passwd:         compat systemd ldap
group:          compat systemd ldap
shadow:         compat ldap
```

### 6.4 Installation of LDAP Auth Modules (Debian/Ubuntu)

```bash
sudo apt install -y libnss-ldapd libpam-ldapd

# During installation, you'll be prompted:
# 1. LDAP server URI: ldap://192.168.1.10
# 2. Base DN: dc=example,dc=com
# 3. LDAP version: 3
# 4. Make local root DB admin: Yes
# 5. Enable NSS databases: passwd, group, shadow
```

### 6.5 nslcd Configuration

The `nslcd` daemon connects to LDAP on behalf of PAM/NSS.

```bash
cat /etc/nslcd.conf
# /etc/nslcd.conf
# nslcd configuration file

uid nslcd
gid nslcd

uri ldap://192.168.1.10/
base dc=example,dc=com
ldap_version 3

# Bind DN (read-only user for lookups)
binddn cn=admin,dc=example,dc=com
bindpw adminpassword

# SSL options
ssl off
tls_cacertfile /etc/ssl/certs/ca-certificates.crt

# Filter options
filter passwd (objectClass=posixAccount)
filter group (objectClass=posixGroup)

# Map attributes
map passwd uid uid
map passwd homeDirectory homeDirectory
```

### 6.6 Verify NSS Integration

```bash
# These should now show LDAP users
getent passwd alice
getent group developers
id alice

# If nslcd is not running
systemctl restart nslcd
systemctl status nslcd
```

### 6.7 PAM Configuration

On Debian/Ubuntu, PAM modules are stacked. The LDAP module is inserted automatically by `pam-auth-update`:

```bash
sudo pam-auth-update

# Enable:
# [*] LDAP Authentication
# [*] LDAP Accounts
# [*] LDAP Password
# [*] LDAP Session
```

Manual `/etc/pam.d/common-auth` example:

```
auth    [success=1 default=ignore]  pam_unix.so nullok_secure
auth    requisite                   pam_deny.so
auth    required                    pam_permit.so
auth    optional                    pam_cap.so
```

After installing `libpam-ldapd`, `pam-auth-update` adds:

```
auth    sufficient                    pam_ldap.so
auth    required                      pam_unix.so nullok_secure try_first_pass
```

### 6.8 Testing LDAP Authentication

```bash
# Test authentication from command line
su - alice

# SSH login from another machine
ssh alice@ldap-client

# Check PAM debug logs
journalctl -u sshd | grep -i ldap
```

### 6.9 Client Configuration for Red Hat/CentOS

```bash
# RHEL uses authconfig or authselect
sudo dnf install -y authselect oddjob-mkhomedir
sudo authselect select sssd with-mkhomedir --force

# Or for direct LDAP (deprecated approach)
sudo authconfig --enableldap \
  --enableldapauth \
  --ldapserver=ldap://192.168.1.10 \
  --ldapbasedn="dc=example,dc=com" \
  --updateall
```





[← Previous](07-section-5-ldap-schemas.md) | [↑ Index](index.md) | [Next →](09-section-7-ldap-over-tls.md)
