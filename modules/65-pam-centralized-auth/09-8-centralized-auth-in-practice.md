## 8. Centralized Auth in Practice

### Complete Workflow: Join a FreeIPA Domain

```bash
# Step 1: Install required packages (RHEL/Fedora)
sudo dnf install -y freeipa-client sssd oddjob oddjob-mkhomedir

# Step 2: Install required packages (Debian/Ubuntu)
sudo apt install -y freeipa-client sssd-tools oddjob-mkhomedir

# Step 3: Verify DNS resolution (critical!)
nslookup $(hostname -d)
nslookup _ldap._tcp.example.com

# Step 4: Join the domain
sudo ipa-client-install \
  --domain=example.com \
  --server=ipa.example.com \
  --realm=EXAMPLE.COM \
  --mkhomedir \
  --enable-dns-updates \
  -p admin \
  -w 'AdminP@ss123'

# Step 5: Verify the join
sudo ipa-client-install --uninstall  # if you need to redo
sudo kinit admin                      # test Kerberos
sudo ipa host-show $(hostname)        # verify host registration
```

```bash
# Step 6: Verify SSSD is running
sudo systemctl status sssd
sudo sssctl domain-status example.com

# Step 7: Test user lookup
getent passwd <ipa-user>
id <ipa-user>
sudo su - <ipa-user>

# Step 8: Test authentication
ssh <ipa-user>@localhost
```

### Joining Active Directory (without FreeIPA)

```bash
# Install packages
sudo dnf install -y realmd sssd adcli samba-common-tools

# Discover the domain
sudo realm discover example.com

# Join (requires domain admin credentials)
sudo realm join --user=administrator example.com

# Verify
sudo realm list
realm leave example.com  # to undo

# Check SSSD config after join
cat /etc/sssd/sssd.conf
# realm join creates this automatically with correct LDAP/Kerberos settings
```

### Troubleshooting SSSD

```bash
# Increase debug level
# Edit /etc/sssd/sssd.conf
debug_level = 9

# Restart SSSD
sudo systemctl restart sssd

# Watch the logs in real-time
sudo tail -f /var/log/sssd/sssd_example.com.log
sudo tail -f /var/log/sssd/sssd_nss.log
sudo tail -f /var/log/sssd/sssd_pam.log

# Clear SSSD cache completely
sudo sss_cache -E
sudo systemctl restart sssd

# Check for SSSD-related issues
sudo sssctl analyze           # SSSD analyze tool (RHEL 8+)
sudo sssctl domain-status example.com

# Common issues and fixes:
# 1. "No such user" → check ldap_user_search_base, ldap_user_object_class
# 2. "Authentication failed" → check auth_provider, ldap_default_bind_dn
# 3. "Access denied" → check access_provider settings
# 4. "Trust refused" → check realm/domain join, time sync (chrony)
# 5. Slow logins → check entry_cache_timeout, ldap_uri (DNS round-robin?)
```

```bash
# Debug a specific user
sudo sssctl user-status <username>

# Test LDAP connectivity directly
ldapsearch -x -H ldaps://ldap.example.com \
  -b "ou=People,dc=example,dc=com" \
  -D "cn=readonly,ou=Service,dc=example,dc=com" \
  -W "(uid=john)"

# Check NSS configuration
getent passwd   # should show local + LDAP users
getent group    # should show local + LDAP groups
```

### Debug Logs Location

```bash
# SSSD log files
/var/log/sssd/
├── sssd.log              # Monitor process log
├── sssd_example.com.log  # Domain-specific log
├── sssd_nss.log          # NSS responder log
├── sssd_pam.log          # PAM responder log
└── sssd_ssh.log          # SSH responder log

# PAM logs (authentication attempts)
journalctl -u sshd        # SSH auth attempts
/var/log/secure            # RHEL (if rsyslog configured)
/var/log/auth.log          # Debian/Ubuntu

# Enable detailed PAM logging
# Add to /etc/pam.d/sshd or system-auth:
auth optional pam_logind.so
```

> 🔍 **Reverse Engineering Insight:** When SSSD joins a domain, it creates a machine account in LDAP/AD. This account has a Kerberos keytab stored in `/etc/sss/sssd.keytab`. If this keytab is lost or corrupted, SSSD cannot authenticate against the directory server. You can regenerate it with `adcli update --computer-password-lifetime=0` (AD) or re-joining the domain.

---



---

[← Previous](08-7-authselect-managing-pam-profiles.md) | [↑ Index](index.md) | [Next →](10-9-pam-security.md)
