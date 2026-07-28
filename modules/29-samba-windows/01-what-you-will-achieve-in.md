## 🎯 What You Will Achieve in Part 29

| Level | Focus | Skills Gained |
|-------|-------|--------------|
| **⭐ Level 1: Basic** | SMB/CIFS Concepts & Samba Overview | Understand the SMB protocol evolution (SMB1/2/3), Samba suite architecture, and basic installation |
| **⭐ Level 2: Intermediary** | File Server & Domain Member | Configure standalone shares, join a domain, mount CIFS shares, use smbclient/smbstatus, integrate with Winbind |
| **⭐ Level 3: Advanced** | AD DC, Security & Performance | Deploy Samba as AD DC, harden SMB encryption/signing, tune performance with multichannel and socket options |

### Why This Part Matters
Most enterprise networks are mixed — Linux servers alongside Windows workstations. Samba makes Linux a first-class citizen in Windows environments, serving files, integrating with Active Directory, and even replacing Windows domain controllers. This part bridges the gap between Linux and Windows.

Complete **15 hands-on practices** across all levels.

> **Real-world relevance**: Organizations rarely run all-Linux or all-Windows environments. Samba lets you share files with Windows users without buying a Windows Server license, join Linux servers to Active Directory for centralized authentication, and even replace Windows domain controllers for cost savings. These skills are in high demand in mixed environments.

**Skills progression in this part**:
- **Basic**: Understand SMB protocol evolution (SMB1→SMB3), install Samba, configure `smb.conf`, verify with `testparm`
- **Intermediary**: Set up standalone file shares, join an AD domain, mount CIFS shares on Linux, use `smbclient` and `smbstatus`
- **Advanced**: Deploy Samba as an AD Domain Controller, harden SMB encryption and signing, tune multichannel performance, troubleshoot with `smbcontrol`


[↑ Index](index.md) | [Next →](02-level-1-basic-smbcifs-concepts.md)
