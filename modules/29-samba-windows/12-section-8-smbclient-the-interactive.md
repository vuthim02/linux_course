## 🔍 Section 8: smbclient — The Interactive SMB Client

smbclient is an FTP-like tool for accessing SMB shares from the command line.

### Listing Shares

```bash
# List all shares on a server (anonymous)
smbclient -L //192.168.1.100 -N

# List shares with credentials
smbclient -L //fileserver -U alice%password

# List shares on a domain member
smbclient -L //dc01 -U administrator -W AD
```

### Interactive Sessions

```bash
# Connect to a share
smbclient //192.168.1.100/shared -U alice

# smbclient: \> prompt
# Available commands:
#   ls             — list files
#   cd DIR         — change directory
#   get FILE       — download file
#   put FILE       — upload file
#   mget PATTERN   — multi-get (with prompt)
#   mput PATTERN   — multi-put (with prompt)
#   rm FILE        — delete file
#   mkdir DIR      — create directory
#   rmdir DIR      — remove directory
#   prompt         — toggle interactive prompts
#   recurse        — toggle recursion for mget/mput
#   tar            — tar operations
#   chmod PERMS FILE — change permissions (if supported)
#   chown USER FILE  — change owner (if supported)
#   du             — directory usage
#   lcd LOCALDIR   — change local directory
#   ! COMMAND      — run local command
#   help           — list commands
#   exit / quit    — disconnect
```

### smbclient Scripting

```bash
# Use smbclient in scripts with -c
smbclient //server/share -U alice%password -c '
   ls
   cd data
   get report.pdf
   put backup.tar.gz
   rm temp.txt
   exit
'
```

### smbclient with Kerberos

```bash
# Get a Kerberos ticket first
kinit alice@AD.COMPANY.COM

# Use the ticket (-k for Kerberos)
smbclient -k //dc01/netlogon -c ls

# Specify the service principal name
smbclient -k //dc01/netlogon -c ls --use-kerberos=required
```





[← Previous](11-section-7-linux-mounting-cifs.md) | [↑ Index](index.md) | [Next →](13-section-9-smbstatus-view-active.md)
