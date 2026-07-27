## 🔍 Section 4: Samba as Domain Member

In this configuration, Samba joins an existing Active Directory domain and authenticates users via Kerberos against Windows Domain Controllers.

### Prerequisites

```bash
# 1. Install required packages
sudo apt install samba krb5-user winbind       # Debian/Ubuntu
sudo dnf install samba krb5-workstation winbind # RHEL/Fedora

# 2. Configure DNS — the AD domain must be resolvable
# Your Linux server's DNS must point to the AD DNS server
cat /etc/resolv.conf
# search ad.company.com
# nameserver 192.168.1.10   (AD DC IP)

# 3. Synchronize time with the Domain Controller
sudo apt install chrony   # or ntpdate
# Kerberos requires time sync within 5 minutes (ideally < 1 min)
sudo chronyd -q 'pool dc01.ad.company.com iburst'
```

### Kerberos Configuration

```ini
# /etc/krb5.conf
[libdefaults]
   default_realm = AD.COMPANY.COM
   dns_lookup_realm = true
   dns_lookup_kdc = true
   ticket_lifetime = 24h
   renew_lifetime = 7d
   forwardable = true

[realms]
   AD.COMPANY.COM = {
      kdc = dc01.ad.company.com
      kdc = dc02.ad.company.com
      admin_server = dc01.ad.company.com
   }

[domain_realm]
   .ad.company.com = AD.COMPANY.COM
   ad.company.com = AD.COMPANY.COM
```

### Join the Domain

```bash
# 1. Test Kerberos connectivity
kinit administrator@AD.COMPANY.COM
# Password: ********

klist
# Ticket cache: FILE:/tmp/krb5cc_0
# Default principal: administrator@AD.COMPANY.COM
# Valid starting: 2024-06-24 10:00:00
# Expires: 2024-06-25 10:00:00

# 2. Configure Samba for domain membership
sudo tee /etc/samba/smb.conf << 'EOF'
[global]
   workgroup = AD
   realm = AD.COMPANY.COM
   security = ADS
   kerberos method = secrets and keytab
   client signing = yes
   client use spnego = yes

   # winbind
   idmap config * : backend = tdb
   idmap config * : range = 10000-19999
   idmap config AD : backend = rid
   idmap config AD : range = 20000-29999

   winbind use default domain = yes
   winbind offline logon = false
   winbind enum users = yes
   winbind enum groups = yes
   winbind refresh tickets = yes

   # template shell
   template shell = /bin/bash
   template homedir = /home/%D/%U

   # logging
   log file = /var/log/samba/log.%m
   log level = 1
EOF

# 3. Join the domain
sudo net ads join -U administrator
# Using short domain name -- AD
# Joined 'FILESERVER' to dns domain 'ad.company.com'

# 4. Verify the computer object in AD
sudo net ads testjoin
# Join is OK
```

### Domain Member smb.conf Explained

```ini
[global]
   security = ADS
   # This tells Samba to use Active Directory (Kerberos + LDAP)
   # instead of its own local password database

   realm = AD.COMPANY.COM
   # The Kerberos realm — MUST be uppercase

   workgroup = AD
   # The NetBIOS domain name (short form, typically uppercase)

   kerberos method = secrets and keytab
   # Options: secrets only, keytab only, secrets and keytab
   # Default: Store the machine account password in secrets.tdb
   # and optionally export to keytab

   idmap config * : backend = tdb
   # Default domain (*) maps to local TDB

   idmap config AD : backend = rid
   # AD domain uses RID algorithm (computes UID/GID from SID)
   # No central mapping file needed — deterministic
   # Alternative: idmap_ldap, idmap_ad, idmap_rfc2307

   winbind use default domain = yes
   # Authenticate as "user" instead of "DOMAIN\user"
```

### Start Winbind

```bash
sudo systemctl enable --now winbind smbd nmbd

# Check winbind status
wbinfo -p
# Ping to winbindd succeeded

# Check domain membership
wbinfo -t
# checking the trust secret for domain AD via RPC calls succeeded

# List domain users
wbinfo -u
# administrator
# alice
# bob
# ...
```

---



---

[← Previous](06-section-3-samba-as-standalone.md) | [↑ Index](index.md) | [Next →](08-level-3-advanced-ad-dc.md)
