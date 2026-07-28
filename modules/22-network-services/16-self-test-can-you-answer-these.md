## 📝 Self-Test — Can You Answer These?

1. What does DHCP stand for and what does it do?
2. What are the four steps of the DORA process?
3. How do you create an Apache virtual host?
4. What is the difference between Apache and Nginx?
5. How do you harden SSH server configuration?
6. What does `PermitRootLogin no` accomplish?
7. How do you generate an SSH key pair?
8. What is the purpose of `ssh-copy-id`?
9. How do you check which ports a service is listening on?
10. What is the difference between `systemctl reload` and `systemctl restart`?
11. How do you allow HTTP through ufw?
12. What does `ssh -L 8080:localhost:80 user@host` do?
13. How do you check the status of a service in systemd?
14. What is the key difference between SSH password and public key auth?
15. How would you troubleshoot a service that won't start?

**Score:** 12/15 correct = ready for Part 23.


## Answer Key

### Q1: What does DHCP stand for and what does it do?
**Answer:** Dynamic Host Configuration Protocol. Automatically assigns IP addresses, subnet masks, gateways, and DNS servers to network devices.

### Q2: What are the four steps of the DORA process?
**Answer:** **D**iscover (client broadcasts), **O**ffer (server responds with IP), **R**equest (client accepts), **A**cknowledge (server confirms).

### Q3: How do you create an Apache virtual host?
**Answer:** Create a config in `/etc/apache2/sites-available/` with `ServerName`, `DocumentRoot`, and `<Directory>` directives, then `a2ensite`.

### Q4: What is the difference between Apache and Nginx?
**Answer:** Apache uses process/thread per connection (prefork/event MPM). Nginx uses async event-driven model, handling thousands of connections with fewer processes.

### Q5: How do you harden SSH server configuration?
**Answer:** Disable root login, use key auth only, limit AuthTries, change default port, use AllowUsers/AllowGroups.

### Q6: What does `PermitRootLogin no` accomplish?
**Answer:** Prevents direct SSH login as root. Admins must log in as regular users and escalate with sudo.

### Q7: How do you generate an SSH key pair?
**Answer:** `ssh-keygen -t ed25519` — creates private and public key files in `~/.ssh/`.

### Q8: What is the purpose of `ssh-copy-id`?
**Answer:** Copies your public key to a remote server's `authorized_keys`, enabling passwordless key-based authentication.

### Q9: How do you check which ports a service is listening on?
**Answer:** `ss -tlnp` or `netstat -tlnp` — lists all listening TCP ports with associated processes.

### Q10: What is the difference between `systemctl reload` and `systemctl restart`?
**Answer:** `reload` applies config changes without downtime (graceful). `restart` stops and starts the service (brief interruption).

### Q11: How do you allow HTTP through ufw?
**Answer:** `sudo ufw allow 80/tcp` or `sudo ufw allow http`

### Q12: What does `ssh -L 8080:localhost:80 user@host` do?
**Answer:** Sets up local port forwarding: traffic to `localhost:8080` goes through `host` to `localhost:80`.

### Q13: How do you check the status of a service in systemd?
**Answer:** `systemctl status service-name` — shows active state, PID, recent logs.

### Q14: What is the key difference between SSH password and public key auth?
**Answer:** Password auth sends credentials over the encrypted channel. Key auth uses cryptographic challenge-response — the private key never leaves your machine.

### Q15: How would you troubleshoot a service that won't start?
**Answer:** Check `systemctl status`, `journalctl -u service`, config file syntax (`nginx -t`), permissions, port conflicts, and SELinux contexts.


*Linux SysAdmin Course | Part 22 of ∞ | Reverse Engineering Approach*
*Previous → Part 21: Time Synchronization — NTP and Chrony*
*Next → Part 23: Virtual Terminals and Console Management*

[← Previous](part21.md) | [Next →](part23.md)



[← Previous](15-whats-coming-in-part-23.md) | [↑ Index](index.md)
