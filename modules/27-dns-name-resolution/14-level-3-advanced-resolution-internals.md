## ⭐ Level 3: Advanced — Resolution Internals and Custom Modules

![Linux Network Stack](https://upload.wikimedia.org/wikipedia/commons/thumb/e/e6/Network_Stack.svg/220px-Network_Stack.svg.png)  
*The glibc resolver — connecting applications to the DNS. Image credit: Wikimedia Commons.*

> **Level 3 Goal:** Understand TCP wrappers (hosts.allow/hosts.deny) and the libwrap mechanism. Configure custom hostname resolution modules. Trace the complete resolution chain from application to wire using strace and glibc internals.

### What You'll Cover
- TCP wrappers: `/etc/hosts.allow` and `/etc/hosts.deny` syntax and logic
- Custom hostname resolution modules (libnss-myhostname, libnss-wins, libnss-mdns)
- The glibc resolver internals: `getaddrinfo()` → nsswitch → modules → DNS
- NSS module ABI and how glibc loads shared libraries
- Deep strace-based debugging of the full resolution chain
- The role of nscd in the resolution pipeline

At the deepest level, name resolution is a chain of function calls through glibc's Name Service Switch. Understanding this chain lets you debug problems that no amount of `dig` output can explain.

At this level you will master:

- **TCP wrappers**: `hosts.allow` and `hosts.deny` control access to services compiled with libwrap (sshd, vsftpd). Syntax: `sshd: 192.168.1.0/24` allows SSH from that subnet. Deny is checked first, then allow. These are being replaced by firewalls and PAM but remain common in legacy systems.
- **Custom NSS modules**: `libnss-myhostname` resolves the local hostname. `libnss-wins` integrates with Samba/NetBIOS. `libnss-mdns` adds mDNS support. Modules are loaded dynamically by glibc based on nsswitch.conf.
- **glibc resolver**: `getaddrinfo("example.com", ...)` is the modern API. It reads nsswitch.conf, calls each module in order (files → dns → ...), and returns the first result. This is why `/etc/hosts` entries override DNS.
- **NSS module ABI**: glibc loads `.so` files from `/lib/x86_64-linux-gnu/`. Each module exports `_nss_*_gethostbyname()` functions. You can write your own NSS modules to resolve from custom sources (LDAP, databases, etc.).
- **strace debugging**: `strace -e trace=network curl example.com` shows every system call. Look for `connect()` calls to see which IP was resolved and which port was used. Combine with `ltrace` to see glibc function calls.


[← Previous](13-section-10-troubleshooting-name-resolution.md) | [↑ Index](index.md) | [Next →](15-section-11-etchostsallow-and-hostsdeny.md)
