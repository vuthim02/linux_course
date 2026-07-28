## ⭐ Level 3: Advanced — AD DC, Security Hardening, and Performance Tuning

![Samba AD DC](https://upload.wikimedia.org/wikipedia/commons/thumb/0/0f/Active_Directory_Domain_Controller.svg/220px-Active_Directory_Domain_Controller.svg.png)  
*Samba as an Active Directory Domain Controller. Image credit: Wikimedia Commons.*

> **Level 3 Goal:** Deploy Samba as an Active Directory Domain Controller (samba-ad-dc). Harden SMB encryption, signing, and protocol versions. Tune performance with socket options and SMB multichannel. Understand NT4-style PDC legacy deployment.

### What You'll Cover
- Deploying Samba as an AD DC with `samba-tool domain provision`
- NT4-style PDC: legacy domain controller configuration
- Security hardening: SMB signing, encryption (AES-128/256), protocol versions
- Performance tuning: socket options, SMB multichannel, read-ahead
- Group Policy integration and LDAP directory management
- Advanced troubleshooting with `smbcontrol` and log level tuning

Deploying Samba as an Active Directory Domain Controller is one of the most powerful — and complex — things you can do with Linux in a Windows environment.

At this level you will master:

- **AD DC deployment**: `samba-tool domain provision --use-rfc2307 --realm=EXAMPLE.COM --adminpass=P@ssw0rd` creates a full AD domain. Samba then acts as LDAP, Kerberos, DNS, and file server in one. This can replace Windows Server for small-to-medium environments.
- **NT4-style PDC**: The legacy approach using `domain logons = yes` and `net sam unicode logon = yes`. Still used in environments with old Windows clients. Limited compared to AD but simpler to set up.
- **Security hardening**: Set `server signing = mandatory`, `smb encrypt = desired` (or `required`), `min protocol = SMB3`, and `map to guest = never`. These settings prevent downgrade attacks and ensure data in transit is encrypted.
- **Performance**: SMB multichannel uses multiple TCP connections for higher throughput. Set `server multi channel support = yes`. Socket options like `SO_RCVBUF` and `SO_SNDBUF` tune buffer sizes for high-latency links.
- **Troubleshooting**: `smbcontrol all ping` tests connectivity. `smbcontrol <process> debug <level>` adjusts verbosity at runtime. Log files in `/var/log/samba/` contain detailed protocol traces when `log level = 3` or higher.


[← Previous](07-section-4-samba-as-domain.md) | [↑ Index](index.md) | [Next →](09-section-5-samba-as-nt4-style.md)
