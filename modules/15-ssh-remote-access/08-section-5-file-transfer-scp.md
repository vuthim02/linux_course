## 🔍 Section 5: File Transfer — SCP, Rsync, SFTP

### SCP (Secure Copy)

```bash
# Copy file TO server
scp localfile.txt user@server:/path/to/destination/

# Copy file FROM server
scp user@server:/path/to/remotefile.txt .

# Copy directory recursively
scp -r /local/dir user@server:/remote/dir/

# Copy with non-standard port
scp -P 2222 file.txt user@server:/tmp/

# Copy between two remote servers (direct)
scp user1@server1:/file.txt user2@server2:/tmp/
```

### rsync (Advanced File Transfer)

rsync is smarter than scp — it only transfers differences.

```bash
# Basic copy (like scp but better)
rsync -av localdir/ user@server:/remote/dir/

# Common flags:
# -a  — archive mode (preserves permissions, timestamps, etc.)
# -v  — verbose
# -z  — compress during transfer
# -P  — show progress AND resume partial transfers
# --delete — remove files at destination that don't exist at source

# Backup with progress
rsync -avzP /home/user/important/ user@server:/backup/

# Mirror a directory (exact copy)
rsync -avz --delete /source/ user@server:/destination/

# Over non-standard SSH port
rsync -avz -e "ssh -p 2222" /source/ user@server:/destination/

# Dry run (see what would happen)
rsync -avz --dry-run /source/ user@server:/destination/
```

### SFTP (SSH File Transfer Protocol)

Interactive file transfer over SSH.

```bash
# Connect
sftp user@server.example.com

# SFTP commands (once connected):
# ls                   — list remote directory
# lls                  — list local directory
# cd                   — change remote directory
# lcd                  — change local directory
# get remote_file      — download
# put local_file       — upload
# get -r remote_dir/   — download directory
# put -r local_dir/    — upload directory
# rm file              — delete remote file
# mkdir dir            — create remote directory
# rmdir dir            — remove remote directory
# !command             — run local command
# help                 — show help
# quit                 — exit

# Batch mode (non-interactive)
echo "put /local/file.txt /remote/" | sftp -b - user@server
```

### Which Tool to Use?

| Tool | Best For |
|------|----------|
| scp | Quick one-off file copies |
| rsync | Large transfers, backups, directory syncing |
| sftp | Interactive file management on remote server |





[← Previous](07-section-4-ssh-server-configuration.md) | [↑ Index](index.md) | [Next →](09-section-6-ssh-config-file.md)
