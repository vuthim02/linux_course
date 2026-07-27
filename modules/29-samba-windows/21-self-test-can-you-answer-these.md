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

---

*Linux SysAdmin Course | Part 29 of ∞ | Reverse Engineering Approach*
*Previous → Part 28: Network File System (NFS)*
*Next → Part 30: RAID — Redundant Array of Independent Disks*

[← Previous](part28.md) | [Next →](part30.md)


---

[← Previous](20-whats-coming-in-part-30.md) | [↑ Index](index.md)
