## 📋 Summary — Complete Command Reference for Part 29

### ⭐ Level 1 Commands: Basic Samba Operations

**Service Management**

| Command | Action |
|---------|--------|
| `sudo systemctl start smbd` | Start Samba file/print services |
| `sudo systemctl stop smbd` | Stop Samba |
| `sudo systemctl restart smbd` | Restart Samba |
| `sudo systemctl enable smbd` | Enable at boot |
| `sudo systemctl start nmbd` | Start NetBIOS name service |

**Configuration Validation**

| Command | Action |
|---------|--------|
| `testparm` | Validate smb.conf syntax |
| `testparm -v` | Show all parameters with defaults |

### ⭐ Level 2 Commands: Shares, Clients, Monitoring, and Winbind

**User and Share Management**

| Command | Action |
|---------|--------|
| `sudo smbpasswd -a USER` | Add SMB user |
| `sudo smbpasswd -x USER` | Delete SMB user |
| `sudo smbpasswd USER` | Change password |
| `sudo pdbedit -L` | List all SMB users |
| `sudo pdbedit -L -v USER` | Show user details |
| `sudo smbcontrol smbd reload-config` | Reload config without restart |

**Client Tools**

| Command | Action |
|---------|--------|
| `smbclient -L //SERVER` | List shares on server |
| `smbclient //SERVER/SHARE -U USER` | Connect to share |
| `smbclient //SERVER/SHARE -c 'CMD1; CMD2'` | Scripted smbclient |
| `smbclient -k //SERVER/SHARE` | Connect with Kerberos |
| `mount -t cifs //SERVER/SHARE /MNT -o OPTIONS` | Mount CIFS share |
| `umount /MNT` | Unmount CIFS share |

**Monitoring**

| Command | Action |
|---------|--------|
| `smbstatus` | Show all connections and locks |
| `smbstatus -L` | Show only locks |
| `smbstatus -p` | Show only processes |
| `smbstatus -S` | Show only shares |
| `smbcontrol smbd close-share NAME` | Disconnect all users from share |

**Winbind**

| Command | Action |
|---------|--------|
| `wbinfo -p` | Ping winbindd |
| `wbinfo -t` | Check domain trust |
| `wbinfo -u` | List domain users |
| `wbinfo -g` | List domain groups |
| `wbinfo -i USER` | Get user info |
| `wbinfo -n USER` | Get SID for username |
| `wbinfo -S SID` | Get UID from SID |
| `wbinfo -s SID` | Get username from SID |
| `getent passwd` | Show all users (including domain) |
| `getent group` | Show all groups (including domain) |

**Samba Config Parameters**

| Parameter | Purpose |
|-----------|---------|
| `workgroup` | NetBIOS workgroup/domain name |
| `server string` | Server description |
| `security` | User, share, ADS, domain |
| `server role` | Standalone, member, dc |
| `server min protocol` | Minimum SMB protocol version |
| `map to guest` | Guest access policy |
| `log level` | Debug verbosity |

### ⭐ Level 3 Commands: AD DC, Security, and Performance

**Active Directory DC**

| Command | Action |
|---------|--------|
| `sudo samba-tool domain provision` | Provision a new AD domain |
| `sudo samba-tool domain join` | Join an existing domain as DC |
| `sudo samba-tool user create USER` | Create AD user |
| `sudo samba-tool group add GROUP` | Create AD group |
| `sudo samba-tool dns add` | Add DNS record |
| `sudo samba-tool domain level show` | Show domain/forest level |
| `sudo samba-tool domain info IP` | Show domain info |

**Advanced Config Parameters**

| Parameter | Purpose |
|-----------|---------|
| `realm` | Kerberos realm (for ADS) |
| `server smb encrypt` | Encryption policy |
| `server signing` | Signing policy |
| `socket options` | TCP performance tuning |
| `disable netbios` | Disable NetBIOS ports 137-139 |
| `idmap config * : backend` | ID mapping backend |
| `idmap config * : range` | UID/GID range for mapping |
| `winbind use default domain` | Strip domain prefix from usernames |

---



---

[← Previous](18-deep-understanding-how-smbcifs-really.md) | [↑ Index](index.md) | [Next →](20-whats-coming-in-part-30.md)
