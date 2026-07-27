## 📋 Section 4: Zones

### 4.1 Zone Statement

Defined in `/etc/bind/named.conf.local`:

```c
// Primary (master) zone
zone "example.com" {
    type master;
    file "/etc/bind/db.example.com";
    allow-transfer { 192.168.1.20; };
    allow-update { none; };
    notify yes;
    also-notify { 192.168.1.20; };
};

// Secondary (slave) zone
zone "example.com" {
    type slave;
    file "/var/cache/bind/db.example.com";
    masters { 192.168.1.10; };
    allow-transfer { none; };
};

// Forward zone
zone "example.com" {
    type forward;
    forwarders { 8.8.8.8; 1.1.1.1; };
    forward only;
};

// Root hints
zone "." {
    type hint;
    file "/etc/bind/db.root";
};
```

### 4.2 Zone Types

| Type | Description | Has File? | Transfers? |
|------|-------------|-----------|------------|
| `master` | Primary authoritative | Yes (read/write) | Can transfer out |
| `slave` | Replica from master | Yes (auto-created) | Usually none |
| `forward` | Forwards queries for this zone | No | No |
| `hint` | Root hints | Yes (static) | No |
| `stub` | Copies only NS records | Yes (auto-created) | No |

---



---

[← Previous](06-section-3-configuration-namedconf.md) | [↑ Index](index.md) | [Next →](08-section-5-zone-files.md)
