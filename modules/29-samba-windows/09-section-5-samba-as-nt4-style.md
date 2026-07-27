## 🔍 Section 5: Samba as NT4-style PDC/DC (Legacy)

Before Active Directory, Windows NT domains used a "Primary Domain Controller" (PDC) with "Backup Domain Controllers" (BDCs). Samba 3.x could act as an NT4-style PDC. This is considered **legacy** but still found in older environments.

### NT4-Style Domain Configuration

```ini
[global]
   workgroup = OLDOMAIN
   server string = %h PDC (Legacy)
   netbios name = PDC01
   security = user
   passdb backend = tdbsam

   # PDC-specific options
   domain logons = yes
   domain master = yes
   preferred master = yes
   os level = 65              # Higher than any Windows machine
   local master = yes

   # Logon scripts
   logon script = logon.bat
   logon path = \\%N\%U\profile
   logon drive = H:
   logon home = \\%N\%U

   # WINS
   wins support = yes

   # Roaming profiles
   logon path = \\%N\profiles\%U
   profile acls = yes

[netlogon]
   comment = Network Logon Service
   path = /var/lib/samba/netlogon
   browseable = no
   read only = no
   guest ok = yes

[profiles]
   comment = Roaming Profiles
   path = /var/lib/samba/profiles
   read only = no
   profile acls = yes
   browseable = no
   create mask = 0600
   directory mask = 0700
```

**Important:** NT4-style domains are deprecated. Use security = ADS (domain member) or the samba-ad-dc for modern deployments.

---



---

[← Previous](08-level-3-advanced-ad-dc.md) | [↑ Index](index.md) | [Next →](10-section-6-samba-as-active.md)
