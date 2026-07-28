## 🎛️ Section 5: DHCP Options

### 5.1 Standard Options

```bash
option subnet-mask 255.255.255.0;
option broadcast-address 192.168.1.255;
option time-offset -18000;              # UTC offset (EST)
option ntp-servers ntp.example.com;
option smtp-server mail.example.com;
option tftp-server-name "tftp.example.com";   # Option 66
option bootfile-name "pxelinux.0";            # Option 67
```

### 5.2 WPAD (Web Proxy Auto-Discovery)

```bash
option wpad-url code 252 = text;
option wpad-url "http://wpad.example.com/wpad.dat";
```

### 5.3 PXE Boot Options

```bash
# BIOS
option tftp-server-name "192.168.1.5";
option bootfile-name "pxelinux.0";

# UEFI
option tftp-server-name "192.168.1.5";
option bootfile-name "bootx64.efi";
```

### 5.4 Vendor-Specific Options (Code 43)

```bash
option space cisco;
option cisco.tftp-server code 1 = ip-address;
option cisco.tftp-server 192.168.1.5;

class "Cisco-Phone" {
    match if substring (option vendor-class-identifier, 0, 5) = "Cisco";
    vendor-option-space cisco;
}
```

### 5.5 Custom Option Definitions

```bash
option custom-provisioning-url code 224 = text;
option custom-provisioning-url "http://provision.example.com/config.cfg";

option custom-log-server code 225 = ip-address;
option custom-log-server 192.168.1.50;
```





[← Previous](07-section-4-static-assignments-reservations.md) | [↑ Index](index.md) | [Next →](09-section-6-multiple-subnets.md)
