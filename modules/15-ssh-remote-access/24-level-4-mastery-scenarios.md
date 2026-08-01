## 👑 Level 4: Mastery — Real-World SSH Scenarios

### Scenario 1: Bastion Host with Certificate Auth

```bash
# SETUP: Bastion + 3 internal servers, all trusting the same CA

# On the CA machine:
ssh-keygen -t ed25519 -f ~/ssh-ca/ca_key
for user in alice bob carol; do
    ssh-keygen -s ~/ssh-ca/ca_key \
        -I "$user@example.com" \
        -n "$user" \
        -V +52w \
        ~/.ssh/id_ed25519.pub
done

# On bastion and every internal server:
# /etc/ssh/sshd_config:
TrustedUserCAKeys /etc/ssh/ca.pub

# User connects:
ssh -J alice@bastion alice@internal-web
# No key setup on individual servers needed
```

### Scenario 2: SFTP-Only File Drop for Clients

```bash
#!/bin/bash
# /usr/local/bin/create-sftp-user.sh
USERNAME=$1
sudo useradd -m -s /sbin/nologin "$USERNAME"
sudo mkdir -p "/home/$USERNAME/incoming" "/home/$USERNAME/outgoing"
sudo chown root:root "/home/$USERNAME"
sudo chmod 755 "/home/$USERNAME"
sudo chown "$USERNAME:$USERNAME" "/home/$USERNAME/incoming"
sudo chown "$USERNAME:$USERNAME" "/home/$USERNAME/outgoing"

# Add SSH key
echo "$2" | sudo tee -a "/home/$USERNAME/.ssh/authorized_keys"

# /etc/ssh/sshd_config:
# Match User alice_client
#     ChrootDirectory /home/alice_client
#     ForceCommand internal-sftp
#     X11Forwarding no
#     AllowTcpForwarding no
```

### Scenario 3: Multiplexed Connection Workflow

```bash
# ~/.ssh/config
Host bastion
    HostName bastion.example.com
    User alice
    ControlMaster auto
    ControlPath ~/.ssh/sockets/%r@%h:%p
    ControlPersist 8h

Host *.internal.example.com
    User alice
    ProxyJump bastion
    ForwardAgent yes
    ControlMaster auto
    ControlPath ~/.ssh/sockets/%r@%h:%p
    ControlPersist 8h

# Daily workflow:
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# All these reuse connections:
ssh internal-web01
ssh internal-db
sftp internal-fileserver
rsync -av internal-web01:/var/www/ ./www/
```

### Scenario 4: Restricted Backup Access with Forced Command

```bash
# Create a dedicated backup key with forced command
ssh-keygen -t ed25519 -f ~/.ssh/backup-key

# In ~/.ssh/authorized_keys on the backup server:
restrict,command="/usr/local/bin/validate-backup.sh" \
    ssh-ed25519 AAAAC3... backup-key

# /usr/local/bin/validate-backup.sh
#!/bin/bash
# Only allow rsync in read-only mode
case "$SSH_ORIGINAL_COMMAND" in
    rsync*--server*)
        eval "$SSH_ORIGINAL_COMMAND"
        ;;
    *)
        echo "Access denied"
        exit 1
        ;;
esac
```

### Scenario 5: Troubleshooting a Complex SSH Issue

```bash
# Problem: SSH to internal-server through bastion fails

# Step 1: Test bastion alone
ssh -vvv bastion.example.com 2>&1 | grep -E "debug1|debug2|Authenticated"

# Step 2: Test ProxyJump
ssh -J bastion.example.com -vvv internal-server 2>&1 | \
    grep -E "debug1.*proxy|Executing|Authenticated"

# Step 3: Check server config
ssh bastion.example.com "sudo sshd -T | grep -E 'permitrootlogin|passwordauth|allowusers'"

# Step 4: Verify agent forwarding
ssh -A bastion.example.com "ssh-add -l"

# Step 5: Test with explicit key
ssh -i ~/.ssh/specific-key -J bastion internal-server
```



[← Previous](22-section-13-ssh-certificates.md) | [↑ Index](index.md) | [Next →](23-rules-of-thumb.md)
