## 🔍 Section 7: Linux Mounting CIFS Shares

Mounting Windows or Samba shares on Linux uses the `cifs` kernel client.

### Basic Mount

```bash
# Install cifs-utils
sudo apt install cifs-utils

# Mount a share
sudo mount -t cifs //192.168.1.100/shared /mnt/smb \
   -o username=alice,password=secret

# Mount with domain
sudo mount -t cifs //dc01/shared /mnt/smb \
   -o username=alice,password=secret,domain=AD
```

### Using a Credentials File

Storing passwords in `mount` commands or `/etc/fstab` is a security risk. Use a credentials file:

```bash
# Create a credentials file
sudo tee /etc/samba/credentials/shared.cred << 'EOF'
username=alice
password=super-secret-password
domain=WORKGROUP
EOF

sudo chmod 600 /etc/samba/credentials/shared.cred

# Mount with credentials file
sudo mount -t cifs //192.168.1.100/shared /mnt/smb \
   -o credentials=/etc/samba/credentials/shared.cred,uid=1000,gid=1000
```

### /etc/fstab Entry

```bash
# /etc/fstab entry for persistent mount
# //server/share  /mount/point  cifs  options  0  0

//192.168.1.100/shared  /mnt/smb  cifs  credentials=/etc/samba/credentials/shared.cred,uid=1000,gid=1000,iocharset=utf8,noexec  0  0
```

### Mount Options Reference

```bash
-o username=USER            # SMB username
-o password=PASS            # SMB password (avoid, use credentials file)
-o domain=DOMAIN            # Authentication domain
-o credentials=FILE         # File containing username/password/domain

-o uid=1000                 # Local owner of mounted files
-o gid=1000                 # Local group of mounted files
-o dir_mode=0755            # Directory permissions
-o file_mode=0644           # File permissions
-o fmask=0137               # File permission mask (subtractive)
-o dmask=0027               # Directory permission mask
-o forceuid                 # Force file owner to uid even if server says otherwise
-o forcegid                 # Force file group to gid

-o iocharset=utf8           # Character set for file names
-o codepage=cp850           # Server codepage (DOS/Windows)

-o noserverino              # Don't use inode numbers from server
-o serverino                # Use inode numbers from server (default)

-o sec=ntlmssp              # Security mode: ntlm, ntlmv2, ntlmssp, krb5
-o vers=3.0                 # SMB protocol version (1.0, 2.0, 2.1, 3.0, 3.1.1)
-o cache=none               # Cache mode: none, strict, loose

-o nobrl                    # Don't send byte range locks to server
-o nostrictsync             # Don't flush on fsync (better performance)

-o multichannel             # SMB3 multichannel (kernel 5.3+)
-o reconn                   # Reconnect if connection drops
-o echo_interval=30         # Keepalive interval in seconds
```

### Multichannel Support

SMB3 multichannel allows using multiple network paths for increased throughput:

```bash
# Mount with multichannel enabled
sudo mount -t cifs //192.168.1.100/shared /mnt/smb \
   -o vers=3.0,multichannel,credentials=/etc/samba/credentials/shared.cred

# Check if multichannel is active
cat /proc/fs/cifs/DebugData | grep -A2 "Multichannel"
```

### Checking Mounted CIFS Shares

```bash
# Standard mount check
mount -t cifs

# Detailed mount info
findmnt -t cifs

# CIFS stats
cat /proc/fs/cifs/Stats

# Per-mount stats
cat /proc/fs/cifs/DebugData
```

---



---

[← Previous](10-section-6-samba-as-active.md) | [↑ Index](index.md) | [Next →](12-section-8-smbclient-the-interactive.md)
