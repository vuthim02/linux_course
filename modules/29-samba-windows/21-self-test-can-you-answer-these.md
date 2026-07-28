## 📝 Self-Test — Can You Answer These?

1. What are the three major versions of the SMB protocol, and which one should be disabled for security?
2. What is the difference between port 139 and port 445 in SMB networking?
3. What does `testparm` do and why should you run it before restarting Samba?
4. How do you add a user to Samba's password database? What is the difference between the system password and the SMB password?
5. In a Samba share definition, what do `create mask` and `directory mask` control?
6. What does `security = ADS` do and what other settings must be configured with it?
7. How does Winbind make Windows domain users appear in Linux commands like `getent passwd`?
8. What is the purpose of the `idmap config` directives?
9. How do you mount a CIFS share persistently via `/etc/fstab` and why should you use a credentials file?
10. What information does `smbstatus` show and how would you use it to find who has a file locked?
11. What is an SMB oplock and how does it affect file caching?
12. How does the SMB2/3 credit system improve performance over SMB1?
13. What are the security implications of SMB1 and how do you disable it in smb.conf?
14. In Samba AD DC mode, what services does `samba-ad-dc` replace from Windows Server?
15. What is SMB3 multichannel and how does it achieve higher throughput?

**Score:** 12/15 correct = ready for Part 30.


## Answer Key

### Q1: What are the three major SMB versions and which one should be disabled?
**Answer:** SMB1 (legacy, insecure — disable), SMB2 (modern, secure), SMB3 (encrypted, multichannel). Disable SMB1 due to vulnerabilities (WannaCry).

### Q2: What is the difference between port 139 and port 445?
**Answer:** Port 139 = NetBIOS over TCP (legacy, SMB1 era). Port 445 = Direct SMB over TCP (modern, SMB2+). Port 445 bypasses NetBIOS layer.

### Q3: What does `testparm` do?
**Answer:** Tests the `smb.conf` configuration file for syntax errors before restarting Samba.

### Q4: How do you add a user to Samba's password database?
**Answer:** `sudo smbpasswd -a username`. The SMB password is separate from the Linux password.

### Q5: What do `create mask` and `directory mask` control?
**Answer:** `create mask` sets permissions for new files (e.g., 0664). `directory mask` sets permissions for new directories (e.g., 0775).

### Q6: What does `security = ADS` do?
**Answer:** Configures Samba as a member of an Active Directory domain. Requires `realm`, `workgroup`, and `winbind` configuration.

### Q7: How does Winbind make Windows users appear in Linux?
**Answer:** Winbind integrates with nsswitch.conf to resolve Windows users/groups via NSS, making `getent passwd` show domain users.

### Q8: What is the purpose of `idmap config` directives?
**Answer:** Maps Windows SIDs to Linux UIDs/GIDs. E.g., `idmap config EXAMPLE : range = 10000-999999` defines the ID mapping range.

### Q9: How do you mount a CIFS share persistently via fstab?
**Answer:** `//server/share /mnt/cifs cifs credentials=/etc/samba/creds,uid=1000,gid=1000 0 0` — use a credentials file for security.

### Q10: What does `smbstatus` show?
**Answer:** Active Samba connections, open files, locked files, and who has them locked.

### Q11: What is an SMB oplock?
**Answer:** Opportunistic lock — allows clients to cache file data locally for performance. Server can recall (break) the oplock when another client accesses the file.

### Q12: How does SMB2/3 credit system improve performance?
**Answer:** Credits control concurrent requests. A client gets multiple credits, enabling parallel operations (vs SMB1's one-at-a-time).

### Q13: What are the security implications of SMB1 and how do you disable it?
**Answer:** SMB1 is vulnerable to MitM attacks, ransomware (WannaCry/EternalBlue). Disable: `server min protocol = SMB2` in smb.conf.

### Q14: In Samba AD DC mode, what services does it replace?
**Answer:** DNS (internal or BIND DLZ), Kerberos (KDC), LDAP, NTLM authentication, Group Policy, and certificate services.

### Q15: What is SMB3 multichannel?
**Answer:** Allows multiple TCP connections simultaneously between client and server, aggregating bandwidth for higher throughput (like NIC teaming at the SMB level).


*Linux SysAdmin Course | Part 29 of ∞ | Reverse Engineering Approach*
*Previous → Part 28: Network File System (NFS)*
*Next → Part 30: RAID — Redundant Array of Independent Disks*

[← Previous](part28.md) | [Next →](part30.md)



[← Previous](20-whats-coming-in-part-30.md) | [↑ Index](index.md)
