## 📋 Summary — Complete Command Reference for Part 15

### Level 1: Basic SSH Commands

| Command | Action |
|---------|--------|
| `ssh user@host` | Connect to remote host |
| `ssh -p PORT user@host` | Connect on specific port |
| `ssh -i KEY user@host` | Use specific private key |
| `ssh -v user@host` | Verbose (debug) output |
| `ssh-keygen -t ed25519` | Generate Ed25519 key pair |
| `ssh-keygen -l -f KEY.pub` | Show key fingerprint |
| `ssh-copy-id user@host` | Copy public key to server |
| `ssh-add` | Add key to agent |
| `ssh-add -l` | List loaded keys |
| `ssh-agent -s` | Start agent |

### Level 2: Configuration and File Transfer

| Command | Action |
|---------|--------|
| `scp file user@host:path` | Copy file to server |
| `scp user@host:file .` | Copy file from server |
| `scp -r dir user@host:path` | Copy directory recursively |
| `rsync -avz src user@host:dest` | Sync files efficiently |
| `sftp user@host` | Interactive file transfer |
| `sudo systemctl status sshd` | Check SSH daemon status |
| `sudo sshd -t` | Test config before restart |
| `sudo systemctl restart sshd` | Restart SSH daemon |
| `cat /etc/ssh/sshd_config` | View server config |

### Level 3: Advanced and Troubleshooting

| Command | Action |
|---------|--------|
| `ssh -L LPORT:RHOST:RPORT user@host` | Local port forwarding |
| `ssh -D PORT user@host` | SOCKS proxy |
| `ssh -N -f user@host` | No command, background |
| `ssh -J user@jumphost user@target` | Jump host (ProxyJump) |
| `autossh -L LPORT:RHOST:RPORT user@host` | Persistent tunnel |
| `ssh-keygen -R hostname` | Remove host key from known_hosts |
| `ssh-keyscan hostname` | Fetch remote host key |
| `ssh -G user@host` | Show effective SSH config |
| `sudo sshd -T` | Show active SSH daemon settings |





[← Previous](15-deep-understanding-how-ssh-encryption.md) | [↑ Index](index.md) | [Next →](17-whats-coming-in-part-16.md)
