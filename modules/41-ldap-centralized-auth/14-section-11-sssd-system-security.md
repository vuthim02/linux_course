## 👤 Section 11: SSSD (System Security Services Daemon)

### 11.1 What is SSSD?

SSSD is a **client-side daemon** that connects to identity providers (LDAP, AD, Kerberos, FreeIPA) and caches credentials locally. It is the **modern replacement** for direct PAM/NSS LDAP integration.

```
Application → PAM → nss_sss → sssd → LDAP/Kerberos/AD
                            ↓
                      Cache (disk/memory)
```

### 11.2 Advantages of SSSD

- **Offline authentication** — users can log in when the LDAP server is unreachable (cached credentials)
- **Caching** — reduces load on LDAP server
- **Multiple domains** — connect to LDAP, AD, and FreeIPA simultaneously
- **Automatic failover** — multiple LDAP servers
- **Fast** — responses from cache instead of network
- **Centralized sudo rules** — via sudoProvider
- **SSH key distribution** — via sshKnownHostsProvider

### 11.3 Installation and Configuration

```bash
# Debian/Ubuntu
sudo apt install -y sssd sssd-ldap libpam-sss libnss-sss

# RHEL/CentOS
sudo dnf install -y sssd sssd-ldap oddjob-mkhomedir

# Create configuration
sudo vim /etc/sssd/sssd.conf
```

```ini
[sssd]
domains = example.com
services = nss, pam, ssh
config_file_version = 2

[domain/example.com]
id_provider = ldap
auth_provider = ldap
chpass_provider = ldap
access_provider = ldap

ldap_uri = ldap://192.168.1.10,ldap://192.168.1.11
ldap_search_base = dc=example,dc=com
ldap_id_use_start_tls = True
ldap_tls_cacert = /etc/ssl/certs/ca-certificates.crt

# Bind DN (read-only user for lookups)
ldap_default_bind_dn = cn=admin,dc=example,dc=com
ldap_default_authtok = adminpassword

# Cache settings
cache_credentials = True
entry_cache_timeout = 3600

# Home directories
override_homedir = /home/%u
override_shell = /bin/bash

# Sudo integration (optional)
sudo_provider = ldap
ldap_sudo_search_base = ou=sudoers,dc=example,dc=com
```

### 11.4 Post-Install Steps

```bash
# Fix permissions (SSSD refuses to start if permissions wrong)
sudo chmod 600 /etc/sssd/sssd.conf

# Enable autofs for home directories (optional)
sudo systemctl enable --now autofs

# Enable mkhomedir on login
# Debian:
sudo pam-auth-update --enable mkhomedir

# RHEL:
sudo authselect select sssd with-mkhomedir --force

# Start SSSD
sudo systemctl enable --now sssd

# Clear cache if needed
sudo systemctl stop sssd
sudo rm -rf /var/lib/sss/db/*
sudo systemctl start sssd
```

### 11.5 Verify SSSD

```bash
# Should return LDAP users
getent passwd alice
id alice

# Check SSSD status
sudo sssctl domain-status example.com

# Check if SSSD sees the domain
sudo sssctl domain-list

# Debug output
sudo sssctl debug-level 9
sudo journalctl -u sssd -f

# Force cache refresh
sudo sssctl cache-remove example.com
```

### 11.6 Troubleshooting SSSD

```bash
# Test LDAP connectivity
sssctl ldap-test

# Check NSS is using SSS
getent passwd alice  # Should work
grep sss /etc/nsswitch.conf
# passwd: compat systemd sss
# group:  compat systemd sss
# shadow: compat sss

# Check PAM config
grep pam_sss /etc/pam.d/common-auth

# If no results from getent:
sudo sssctl cache-remove
# Make sure nslcd is stopped (it conflicts with sssd)
sudo systemctl stop nslcd
sudo systemctl disable nslcd
```

---



---

[← Previous](13-section-10-389-directory-server.md) | [↑ Index](index.md) | [Next →](15-section-12-freeipa.md)
