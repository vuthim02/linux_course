## 💻 Section 12: PXE Booting

### 12.1 What is PXE?

**PXE** (Preboot eXecution Environment) allows network-booting a computer with no OS. The client:
1. Gets an IP via DHCP
2. Finds a TFTP/HTTP server (option 66)
3. Downloads a bootloader (option 67)
4. Boots the OS installer

### 12.2 PXE DHCP Options

```bash
option tftp-server-name "192.168.1.5";    # Option 66
option bootfile-name "pxelinux.0";         # Option 67
```

### 12.3 BIOS vs UEFI

```bash
# BIOS/Legacy
option bootfile-name "pxelinux.0";

# UEFI x64
option bootfile-name "bootx64.efi";

# UEFI IA32
option bootfile-name "bootia32.efi";

# UEFI HTTP Boot
option bootfile-name "http://install.example.com/bootx64.efi";
```

### 12.4 Architecture Type Codes

| Code | Architecture |
|------|-------------|
| 0 | BIOS x86 |
| 6 | EFI IA32 |
| 7 | EFI x64 |
| 9 | EFI x64 with HTTP |

### 12.5 Multi-Architecture PXE with Classes

```bash
class "pxeclients" {
    match if substring (option vendor-class-identifier, 0, 9) = "PXEClient";
}

subnet 192.168.1.0 netmask 255.255.255.0 {
    option routers 192.168.1.1;
    range 192.168.1.100 192.168.1.200;

    # BIOS
    group {
        match if option arch-type = 0;
        option tftp-server-name "192.168.1.5";
        option bootfile-name "pxelinux.0";
    }
    # UEFI x64
    group {
        match if option arch-type = 7;
        option tftp-server-name "192.168.1.5";
        option bootfile-name "bootx64.efi";
    }
    # UEFI HTTP
    group {
        match if option arch-type = 9;
        option bootfile-name "http://192.168.1.5/bootx64.efi";
    }
}
```

### 12.6 iPXE Chain-Loading

```bash
class "ipxe" {
    match if substring (option vendor-class-identifier, 0, 10) = "iPXE";
}

group {
    match if not (exists members of "ipxe");
    option bootfile-name "undionly.kpxe";     # Bootstrap iPXE
}
group {
    match if exists members of "ipxe";
    option bootfile-name "http://server/boot.ipxe";  # Full script
}
```

### 12.7 PXE Infrastructure

```
DHCP (67/udp) → 66/67 options → TFTP (69/udp) or HTTP (80/tcp)
    │                                │
    │  Offers IP, TFTP server        │  Sends pxelinux.0, kernel, initrd
    │<───────────────────────────────>│
```

```bash
sudo apt install -y tftpd-hpa nginx
sudo mkdir -p /srv/tftp
sudo cp /usr/lib/PXELINUX/pxelinux.0 /srv/tftp/
sudo systemctl enable --now tftpd-hpa
```

---



---

[← Previous](15-section-11-dhcpv6.md) | [↑ Index](index.md) | [Next →](17-section-13-15-hands-on-practices.md)
