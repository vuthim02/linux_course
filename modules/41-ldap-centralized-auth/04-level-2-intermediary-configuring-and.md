## ⭐ Level 2: Intermediary — Configuring and Managing OpenLDAP

![OpenLDAP logo — the open-source LDAP directory server](https://upload.wikimedia.org/wikipedia/commons/thumb/8/84/OpenLDAP_logo.svg/800px-OpenLDAP_logo.svg.png)

> **Level 2 Goal:** Configure OpenLDAP using OLC, manage entries with LDIF, set up schemas, integrate with PAM/NSS for authentication, enable TLS, and use browser tools.

### What You'll Cover
- OpenLDAP Configuration (OLC / cn=config) via `ldapmodify`
- LDIF editing for adding, modifying, and deleting entries
- Custom schemas for application-specific attributes
- PAM and NSS integration for Linux system authentication
- Enabling TLS with self-signed and Let's Encrypt certificates
- LDAP browser tools (`ldapsearch`, Apache Directory Studio, JXplorer)
- SSSD configuration for caching and offline authentication

At this level you configure OpenLDAP for production use and integrate it with Linux system authentication.

At this level you will practice:

- **OLC configuration**: Modern OpenLDAP uses `cn=config` instead of `slapd.conf`. Modify configuration with `ldapmodify -D "cn=admin,cn=config" -W` and LDIF changes. This allows runtime configuration changes without restarting the server.
- **PAM/NSS integration**: `libpam-ldap` and `libnss-ldap` allow Linux to authenticate users against LDAP. Edit `/etc/nsswitch.conf` to add `ldap` to the `passwd` and `group` lines. Users appear in `getent passwd` and can log in with `su - ldapuser`.
- **TLS**: Generate certificates (Let's Encrypt or self-signed). Configure `olcTLSCACertificateFile`, `olcTLSCertificateFile`, `olcTLSCertificateKeyFile` in `cn=config`. Enable with `slapd -h "ldaps:///"`. Test with `openssl s_client -connect server:636`.
- **SSSD**: System Security Services Daemon provides caching, offline authentication, and a more robust NSS/PAM integration than `libnss-ldap`. Configure `/etc/sssd/sssd.conf` with LDAP backend. SSSD caches credentials so users can log in even when the LDAP server is down.
- **Browser tools**: `ldapsearch -x -b "dc=example,dc=com" "(objectClass=*)"` queries all entries. Apache Directory Studio provides a GUI for browsing and editing. JXplorer is a lightweight Java-based browser.


[← Previous](03-section-2-openldap-installation.md) | [↑ Index](index.md) | [Next →](05-section-3-openldap-configuration-cnconfig.md)
