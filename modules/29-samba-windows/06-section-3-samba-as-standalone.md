## 🔍 Section 3: Samba as Standalone File Server

This is the most common use case — a Linux server providing file shares to Windows clients (or other Linux clients via SMB).

### Minimal Standalone Configuration

```ini
[global]
   workgroup = WORKGROUP
   server string = %h Samba Server
   netbios name = FILESERVER
   security = user
   map to guest = Bad User
   dns proxy = no

[shared]
   comment = Public Share
   path = /srv/samba/shared
   read only = no
   guest ok = yes
   browseable = yes
   create mask = 0755
   directory mask = 0755
```

### Share Definition Directives Explained

```ini
[sharename]
   # ESSENTIAL
   path = /path/to/share           # Directory on disk to share
   comment = Human description     # Seen in Windows Explorer

   # ACCESS CONTROL
   valid users = user1, user2      # Who can access (space/comma separated)
   invalid users = user3           # Explicitly denied
   read list = user4, @group1      # Read-only for these users/groups
   write list = user5, @group2     # Writable for these users/groups
   admin users = root              # Treated as root (careful!)

   # GUEST ACCESS
   guest ok = yes                  # Allow guest (anonymous) access
   guest only = yes                # Force guest even if credentials provided
   map to guest = Bad User         # Global: map unknown users to guest
   # map to guest options: Never, Bad User, Bad Password

   # PERMISSIONS
   read only = no                  # Writable share
   browseable = yes                # Visible in network browser
   hidden = no                     # Hidden even if browseable=yes (Windows)
   create mask = 0644              # File permission mask after creation
   directory mask = 0755           # Directory permission mask
   force create mode = 0644        # OR with create mask (always set these bits)
   force directory mode = 0755     # OR with directory mask

   # INHERITANCE
   inherit permissions = yes       # Inherit from parent directory
   inherit owner = yes             # New files owned by share directory owner
   inherit acls = yes              # Inherit ACLs from parent

   # OTHER
   veto files = /*.tmp/*.log/      # Hide these files
   delete veto files = yes         # Delete vetoed files on directory delete
   hide unreadable = yes           # Hide files user can't read
   hide unwriteable files = yes    # Hide files user can't write
```

### Setting Up User-Level Security

```bash
# 1. Create Linux users
sudo useradd -m -s /usr/sbin/nologin alice
sudo useradd -m -s /usr/sbin/nologin bob

# 2. Create Samba passwords (separate from Linux passwords!)
sudo smbpasswd -a alice
# New SMB password: ********
# Retype new SMB password: ********
# Added user alice.

sudo smbpasswd -a bob

# 3. View the password database
sudo pdbedit -L
# alice:1000:alice
# bob:1001:bob

# 4. Show detailed user info
sudo pdbedit -L -v alice
```

### Samba Password Storage

```
# Default backend: tdbsam (trivial database)
# Stored in: /var/lib/samba/private/passdb.tdb

# Older backends:
#   smbpasswd: /etc/samba/smbpasswd (plain text, legacy)
#   ldapsam:   LDAP directory

# To see which backend is active:
testparm -s --parameter-name "passdb backend" 2>/dev/null
```

### Complete Share Example: Department Shares

```ini
[global]
   workgroup = COMPANY
   server string = File Server
   security = user
   map to guest = Never
   log file = /var/log/samba/log.%m
   max log size = 50

[finance]
   comment = Finance Department
   path = /srv/samba/finance
   valid users = @finance, alice (manager)
   read only = no
   create mask = 0660
   directory mask = 0770
   browseable = no           # Hidden from browsing, need path

[engineering]
   comment = Engineering Team
   path = /srv/samba/engineering
   valid users = @engineers
   read only = no
   create mask = 0664
   directory mask = 0775

[public]
   comment = Company Public
   path = /srv/samba/public
   guest ok = yes
   read only = no
   create mask = 0644
   directory mask = 0755
```

### Directories and Permissions

```bash
# Create the share directories
sudo mkdir -p /srv/samba/{finance,engineering,public}

# Set group ownership
sudo groupadd finance
sudo groupadd engineers
sudo usermod -aG finance alice
sudo usermod -aG engineers bob

# Set filesystem permissions that match Samba masks
sudo chown root:finance /srv/samba/finance
sudo chmod 2770 /srv/samba/finance       # 2 = setgid: new files inherit group

sudo chown root:engineers /srv/samba/engineering
sudo chmod 2775 /srv/samba/engineering

sudo chown nobody:nogroup /srv/samba/public
sudo chmod 2775 /srv/samba/public
```

---



---

[← Previous](05-level-2-intermediary-file-serving.md) | [↑ Index](index.md) | [Next →](07-section-4-samba-as-domain.md)
