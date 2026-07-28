## 🏛️ Section 12: FreeIPA

### 12.1 What is FreeIPA?

FreeIPA is an **integrated identity management solution** that combines:

- **389 Directory Server** (LDAP)
- **MIT Kerberos** (authentication)
- **BIND with DNSSEC** (DNS)
- **Dogtag Certificate System** (CA)
- **NTP** (time synchronization)
- **Web UI** (Cockpit-based management interface)

It provides a **one-stop shop** for domain management, similar to Microsoft Active Directory but for Linux/Unix environments.

### 12.2 When to Use FreeIPA vs. OpenLDAP

| Scenario | Recommendation |
|----------|---------------|
| Small team (10 users, 5 servers) | OpenLDAP + SSSD |
| Enterprise (500+ users, 100+ servers) | FreeIPA |
| Need single sign-on (Kerberos) | FreeIPA |
| Need certificate management | FreeIPA |
| Already have AD | SSSD with AD provider |
| Minimal, lightweight setup | OpenLDAP |

### 12.3 Installation (RHEL 8/9)

```bash
# Prerequisites
sudo hostnamectl set-hostname ipa.example.com
echo "192.168.1.10 ipa.example.com" >> /etc/hosts

# Install FreeIPA server
sudo dnf install -y freeipa-server freeipa-server-dns

# Run installer
sudo ipa-server-install \
  --realm=EXAMPLE.COM \
  --domain=example.com \
  --hostname=ipa.example.com \
  --ds-password=dspassword \
  --admin-password=adminpassword \
  --setup-dns \
  --no-forwarders \
  --unattended
```

### 12.4 Installation (Ubuntu)

```bash
sudo apt install -y freeipa-server freeipa-server-dns
sudo ipa-server-install
```

### 12.5 Basic FreeIPA Commands

```bash
# Authenticate as admin
kinit admin

# Add user
ipa user-add alice \
  --first=Alice --last=Smith \
  --email=alice@example.com \
  --password

# Add group
ipa group-add developers --desc="Development Team"

# Add user to group
ipa group-add-member developers --users=alice

# Search users
ipa user-find alice

# Show user details
ipa user-show alice

# Disable user
ipa user-disable alice

# Enable user
ipa user-enable alice

# Delete user
ipa user-del alice

# Add sudo rule
ipa sudorule-add full_admin \
  --hostcat=all --cmdcat=all --runasusercat=all

ipa sudorule-add-user full_admin --users=alice
```

### 12.6 FreeIPA Client Setup

```bash
# On each client machine
sudo dnf install -y freeipa-client

sudo ipa-client-install \
  --domain=example.com \
  --server=ipa.example.com \
  --realm=EXAMPLE.COM \
  --mkhomedir \
  --enable-dns-updates

# Verify
getent passwd alice
kinit alice
klist
```

### 12.7 FreeIPA Web UI

Access the web interface at `https://ipa.example.com/ipa/ui/`:

```
Active Users    ──────── User management
Policy          ──────── Password policies, HBAC, sudo
Authentication  ──────── Kerberos, OTP, certificates
Network Services ──────── DNS, NTP, services
Role-Based ACL  ──────── Delegation, roles, privileges
```





[← Previous](14-section-11-sssd-system-security.md) | [↑ Index](index.md) | [Next →](16-section-13-kerberos.md)
