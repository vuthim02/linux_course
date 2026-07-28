## 🔍 Section 8: /etc/hosts and /etc/hostname — Hostname Configuration

### /etc/hostname

This file contains the system's hostname — a single line.

```bash
# View current hostname
cat /etc/hostname

# Set hostname temporarily (immediate, lost on reboot)
sudo hostname server01.example.com

# Set hostname permanently (survives reboot)
sudo hostnamectl set-hostname server01.example.com

# Or directly edit the file
echo "server01.example.com" | sudo tee /etc/hostname

# Set pretty hostname (for desktops)
sudo hostnamectl set-hostname "My Server" --pretty

# Set all three: static, pretty, transient
sudo hostnamectl set-hostname server01.example.com --static
```

### Viewing Hostname Information

```bash
# Display hostname in various forms
hostname
hostname -f   # FQDN
hostname -s   # Short name (first component)
hostname -d   # Domain name
hostname -i   # IP address from /etc/hosts
hostname -A   # All FQDNs

# With hostnamectl
hostnamectl
```

Output of `hostnamectl`:
```
   Static hostname: server01.example.com
   Pretty hostname: My Server
         Icon name: computer-vm
           Chassis: vm
        Machine ID: abc1234567890def1234567890abcdef
           Boot ID: def1234567890abcdef1234567890abcd
  Operating System: Ubuntu 22.04 LTS
            Kernel: Linux 6.2.0-26-generic
      Architecture: x86-64
```

### /etc/hosts — Local DNS Resolution

This file maps IP addresses to hostnames, bypassing DNS. It is checked BEFORE DNS (unless configured otherwise in `/etc/nsswitch.conf`).

```bash
cat /etc/hosts
```

```
127.0.0.1       localhost
127.0.1.1       server01.example.com server01
192.168.1.100   server01 server01.example.com

# The following lines are desirable for IPv6 capable hosts
::1             ip6-localhost ip6-loopback
fe00::0         ip6-localnet
ff00::0         ip6-mcastprefix
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters
```

### /etc/nsswitch.conf — Name Service Switch

Controls the order of name resolution:

```bash
cat /etc/nsswitch.conf | grep hosts
```

```
hosts:          files dns myhostname
```

This means:
1. `files` → check `/etc/hosts` first
2. `dns` → check DNS next
3. `myhostname` → check own hostname last

### Practical Uses for /etc/hosts

```bash
# Block a website (redirect to localhost)
echo "127.0.0.1   ads.example.com" | sudo tee -a /etc/hosts

# Override DNS for testing (point domain to staging server)
echo "10.0.0.50   production.example.com" | sudo tee -a /etc/hosts

# Add entries for local development
echo "127.0.0.1   myapp.local" | sudo tee -a /etc/hosts

# Verify resolution
getent hosts production.example.com
```

### How Hostname Resolution Works

```
Application calls gethostbyname("example.com")
    ↓
nsswitch.conf says: files → dns
    ↓
Check /etc/hosts for match
    ↓ (if not found)
DNS resolver queries /etc/resolv.conf for nameservers
    ↓ (if not found)
Return error or fall back to myhostname
```





[← Previous](10-section-7-rhelcentosfedora-network-configuration.md) | [↑ Index](index.md) | [Next →](12-section-9-etcresolvconf-and-dns.md)
