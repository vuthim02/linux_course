## 🧠 Deep Understanding — Network Services Internals

### How SSH Authentication Works

```
1. Client connects to server
2. Server sends its host key (public)
3. Client checks known_hosts for server's key
4. Key exchange establishes encrypted channel
5. Client authenticates:

   Option A: Password
   - Client sends password (encrypted)
   - Server checks against /etc/shadow

   Option B: Public Key
   - Client proves possession of private key
   - Server checks ~/.ssh/authorized_keys
   
   Option C: Certificate
   - Signed certificate presented
   - Server validates CA signature

6. Session begins (encrypted)
```

### How DHCP Works in Detail

```
DHCP offers more than just an IP address:

Option 1:  Subnet mask (255.255.255.0)
Option 3:  Default gateway (192.168.1.1)
Option 6:  DNS servers (8.8.8.8)
Option 15: Domain name (example.com)
Option 42: NTP servers
Option 66: TFTP server (for PXE boot)
Option 67: Boot file (for PXE boot)
```

### Service Management Best Practices

```
1. Use systemd service files, not init scripts
   - Consistent interface across all services
   - Proper dependency handling
   - Resource control (CPU, memory limits)

2. Enable on boot only for services that need it
   - systemctl enable → Starts at boot
   - Just because it's installed doesn't mean it should run

3. Use reload instead of restart when possible
   - reload: Re-read config without dropping connections
   - restart: Drop connections, start fresh

4. Logs go to journald, not just files
   - journalctl -u service for service-specific logs
   - journalctl -f for real-time monitoring
```





[← Previous](12-practice-section-15-hands-on-exercises.md) | [↑ Index](index.md) | [Next →](14-summary-complete-command-reference-for.md)
