## 5. SSSD Architecture

### What Is SSSD?

SSSD (System Security Services Daemon) is the modern bridge between Linux systems and centralized identity providers (LDAP, Active Directory, FreeIPA, Kerberos).

```
┌──────────────────────────────────────────────────────────┐
│                    APPLICATIONS                             │
│  login, sshd, sudo, su, getent, id, ...                   │
├──────────────────────────────────────────────────────────┤
│                    NSS / PAM                                │
│  nss_sss.so  →  name service switch (getent passwd)       │
│  pam_sss.so  →  authentication (pam_authenticate)         │
├──────────────────────────────────────────────────────────┤
│                    SSSD DAEMON                              │
│  ┌──────────────────────────────────────────────┐          │
│  │  sssd (monitor)                               │          │
│  │  Manages all child processes                  │          │
│  ├──────────────────────────────────────────────┤          │
│  │  sss_nss (NSS responder)                      │          │
│  │  Handles getent passwd, getent group, etc.    │          │
│  ├──────────────────────────────────────────────┤          │
│  │  sss_pam (PAM responder)                      │          │
│  │  Handles authentication requests              │          │
│  ├──────────────────────────────────────────────┤          │
│  │  sss_ssh (SSH responder)                      │          │
│  │  Provides SSH public keys from LDAP           │          │
│  ├──────────────────────────────────────────────┤          │
│  │  sss_sudo (Sudo responder)                    │          │
│  │  Provides sudo rules from LDAP                │          │
│  └──────────────────────────────────────────────┘          │
├──────────────────────────────────────────────────────────┤
│                    DATA PROVIDERS                           │
│  ┌──────────┐  ┌──────────────┐  ┌─────────────────┐     │
│  │ LDAP/ID  │  │ Kerberos/    │  │ Local Files      │     │
│  │ Provider │  │ AD Provider  │  │ Provider         │     │
│  │          │  │              │  │ (/etc/passwd)    │     │
│  └──────────┘  └──────────────┘  └─────────────────┘     │
├──────────────────────────────────────────────────────────┤
│                    CACHE (ldb database)                     │
│  /var/lib/sss/db/config.ldb  (SSSD configuration)         │
│  /var/lib/sss/mc/passwd.ldb  (memory cache)               │
│  /var/lib/sss/mc/group.ldb                                │
│  Enables OFFLINE authentication when LDAP is unreachable  │
└──────────────────────────────────────────────────────────┘
```

### SSSD Configuration — /etc/sssd/sssd.conf

```bash
# /etc/sssd/sssd.conf
# Permissions MUST be 0600 (SSSD refuses to start otherwise)
sudo chmod 600 /etc/sssd/sssd.conf
sudo chown root:root /etc/sssd/sssd.conf

# [sssd] section — global settings
[sssd]
domains = example.com
config_file_version = 2
services = nss, pam, ssh, sudo

# Domain configuration
[domain/example.com]
# Identity provider
id_provider = ldap

# Authentication provider
auth_provider = ldap

# Access provider (who can log in)
access_provider = ldap

# Chage provider (password changes)
chpass_provider = ldap

# Cache provider
cache_provider = ldap

# LDAP server URIs
ldap_uri = ldaps://ldap.example.com
ldap_backup_uri = ldaps://ldap-backup.example.com

# LDAP search bases
ldap_search_base = dc=example,dc=com
ldap_user_search_base = ou=People,dc=example,dc=com
ldap_group_search_base = ou=Groups,dc=example,dc=com

# Bind DN (service account for LDAP queries)
ldap_default_bind_dn = cn=readonly,ou=Service,dc=example,dc=com
ldap_default_authtok = P@ssw0rd123
ldap_default_authtok_type = password

# TLS settings
ldap_tls_reqcert = demand
ldap_tls_cacert = /etc/openldap/cacerts/ca.crt
ldap_tls_cacertdir = /etc/openldap/cacerts

# Schema settings
ldap_schema = rfc2307bis
ldap_user_object_class = posixAccount
ldap_user_name = uid
ldap_group_object_class = posixGroup
ldap_group_name = cn

# User and group maps
ldap_user_gecos = gecos
ldap_user_home_directory = homeDirectory
ldap_user_shell = loginShell
ldap_user_uid_number = uidNumber
ldap_group_member = member

# SSH key lookup
ldap_user_ssh_public_key = sshPublicKey

# Kerberos (if using Kerberos for auth)
# auth_provider = krb5
# krb5_server = kdc.example.com
# krb5_realm = EXAMPLE.COM
# krb5_kdcip = kdc.example.com

# Caching settings
entry_cache_timeout = 300
entry_cache_user_timeout = 300
entry_cache_group_timeout = 300

# Offline authentication
cache_credentials = true
krb5_store_password_if_offline = true

# Debugging (0=off, 1=critical, 3=info, 6=trace, 9=extreme)
debug_level = 3

# Access control
ldap_access_order = expire
ldap_account_expire_policy = shadow
```

### SSSD Providers Breakdown

```
┌───────────────────────────────────────────────────────────┐
│  PROVIDER TYPE   │  PURPOSE                                │
├───────────────────────────────────────────────────────────┤
│  id_provider      │  Get user/group info (UID, GID, home)  │
│  auth_provider    │  Authenticate the user (password/Kerb) │
│  access_provider  │  Allow/deny login (time, host, etc.)   │
│  chpass_provider  │  Change user password                   │
│  sudo_provider    │  Load sudo rules from LDAP             │
│  selinux_provider │  Load SELinux user mappings             │
│  autofs_provider  │  Automount map entries                  │
│  hostid_provider  │  Host identity                         │
│  subdomains_prov. │  Subdomain trusts (AD)                  │
└───────────────────────────────────────────────────────────┘
```

### SSSD Caching — How Offline Auth Works

```
┌──────────────────────────────────────────────────────────┐
│  FIRST LOGIN (online)                                      │
│  1. SSSD queries LDAP → gets user info + password hash    │
│  2. Stores in /var/lib/sss/db/config.ldb ( ldb )         │
│  3. Memory cache: /var/lib/sss/mc/passwd.ldb              │
│  4. Authenticated successfully                            │
├──────────────────────────────────────────────────────────┤
│  LDAP UNREACHABLE (offline)                                │
│  1. SSSD detects LDAP timeout                              │
│  2. Falls back to cached credentials                       │
│  3. Checks cached password hash (stored securely)         │
│  4. Authenticates offline if cache is valid                │
│  5. Logs "Going offline" to syslog                         │
├──────────────────────────────────────────────────────────┤
│  LDAP RESTORED (online again)                              │
│  1. SSSD detects LDAP is reachable                         │
│  2. Refreshes cache with fresh data from LDAP              │
│  3. Logs "Going online" to syslog                          │
│  4. Next login uses live LDAP data                         │
└──────────────────────────────────────────────────────────┘
```

```bash
# Check SSSD cache contents
sudo sss_cache -E                    # Expire all cached entries
sudo ldbsearch -H /var/lib/sss/db/config.ldb "(objectClass=user)" | head -50

# Check if SSSD is using cache
sudo sssctl domain-status example.com

# Force online check
sudo sssctl domain-status example.com --online
```

> 🔍 **Reverse Engineering Insight:** SSSD's memory cache (`/var/lib/sss/mc/`) is memory-mapped, meaning `getent passwd` reads directly from shared memory without even contacting the SSSD daemon. This is why `getent passwd <ldap_user>` is near-instant even with thousands of LDAP users.





[← Previous](05-4-password-policies.md) | [↑ Index](index.md) | [Next →](07-6-ldap-integration.md)
