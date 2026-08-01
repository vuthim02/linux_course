## 📝 Self-Test — Can You Answer These?

1. What are the three layers of the SSH protocol?
2. What is the difference between a host key and a user key?
3. What command generates an Ed25519 SSH key pair?
4. What permissions should ~/.ssh and ~/.ssh/authorized_keys have?
5. How does `ssh-copy-id` work?
6. What is the purpose of ssh-agent?
7. What is the difference between `scp` and `rsync`?
8. What does `ssh -L 8080:localhost:80 user@server` do?
9. What three settings should you change to harden SSH?
10. How do you test sshd_config before restarting?
11. What does `MaxAuthTries` do in sshd_config?
12. How do you copy a file FROM a remote server?
13. What is a SOCKS proxy and how do you create one with SSH?
14. What does `ssh-keygen -R hostname` do?
15. How does fail2ban protect SSH?

**Score:** 12/15 correct = ready for Part 16.


## Answer Key

### Q1: What are the three layers of the SSH protocol?
**Answer:** 1) Transport layer (encryption, key exchange), 2) Authentication layer (user auth), 3) Connection layer (tunnels, channels, sessions).

### Q2: What is the difference between a host key and a user key?
**Answer:** Host key identifies the server (checked by the client to verify the server). User key authenticates the user to the server.

### Q3: What command generates an Ed25519 SSH key pair?
**Answer:** `ssh-keygen -t ed25519 -C "your_email@example.com"`

### Q4: What permissions should ~/.ssh and ~/.ssh/authorized_keys have?
**Answer:** `~/.ssh` = 700 (drwx------), `authorized_keys` = 600 (-rw-------). SSH refuses to work with lax permissions.

### Q5: How does `ssh-copy-id` work?
**Answer:** Copies your public key to the remote server's `~/.ssh/authorized_keys` file, enabling key-based login.

### Q6: What is the purpose of ssh-agent?
**Answer:** Caches your decrypted private key in memory so you don't have to enter the passphrase repeatedly during a session.

### Q7: What is the difference between `scp` and `rsync`?
**Answer:** `scp` copies files (no resume, no delta). `rsync` syncs with delta transfer (only sends changed parts), supports resume, compression, and deletion.

### Q8: What does `ssh -L 8080:localhost:80 user@server` do?
**Answer:** Creates a local port forward: traffic to local port 8080 is tunneled through `server` to `localhost:80` on the remote side.

### Q9: What three settings should you change to harden SSH?
**Answer:** `PermitRootLogin no`, `PasswordAuthentication no`, `MaxAuthTries 3`.

### Q10: How do you test sshd_config before restarting?
**Answer:** `sshd -t` — tests the configuration file for syntax errors without restarting.

### Q11: What does `MaxAuthTries` do?
**Answer:** Limits the number of authentication attempts per connection (default 6). Prevents brute-force attacks.

### Q12: How do you copy a file FROM a remote server?
**Answer:** `scp user@server:/path/to/file /local/path` — reverse of the usual copy direction.

### Q13: What is a SOCKS proxy and how do you create one with SSH?
**Answer:** SOCKS proxies TCP connections through a relay host. Create with: `ssh -D 1080 user@server` — listens locally on port 1080.

### Q14: What does `ssh-keygen -R hostname` do?
**Answer:** Removes all keys for `hostname` from `~/.ssh/known_hosts` — used when the server's key has changed (e.g., after reinstall).

### Q15: How does fail2ban protect SSH?
**Answer:** Monitors auth logs for repeated failed logins. After `maxretry` failures from an IP, it bans that IP via firewall rules for `bantime` seconds.


[← Previous](17-whats-coming-in-part-16.md) | [↑ Index](index.md) | [Next →](19-section-10-agent-forwarding-and-multiplexing.md)
