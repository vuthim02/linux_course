## 🛡️ Section 9: Access Control

### 9.1 ACL Definitions

```c
acl internal {
    192.168.0.0/16;
    10.0.0.0/8;
    172.16.0.0/12;
    localhost;
};

acl slaves {
    192.168.1.20;
    10.10.0.10;
};

options {
    allow-query { internal; };
    allow-recursion { internal; };
    allow-transfer { none; };
};
```

### 9.2 Using ACLs

```c
zone "example.com" {
    type master;
    file "/etc/bind/db.example.com";
    allow-query { any; };
    allow-transfer { slaves; };
    allow-update { admin; };
};
```

### 9.3 Views (Split DNS)

Serve different data based on client IP:

```c
acl internal-clients {
    192.168.0.0/16;
    10.0.0.0/8;
    localhost;
};

view "internal" {
    match-clients { internal-clients; };
    recursion yes;

    zone "example.com" {
        type master;
        file "/etc/bind/internal/db.example.com";
    };
};

view "external" {
    match-clients { any; };
    recursion no;

    zone "example.com" {
        type master;
        file "/etc/bind/external/db.example.com";
    };
};
```

**Internal zone file** (private IPs):
```dns
www  IN A 192.168.1.100
mail IN A 192.168.1.101
```

**External zone file** (public IPs):
```dns
www  IN A 203.0.113.100
mail IN A 203.0.113.101
```

**Rules:** More-specific views first; all zones must be in a view; root hints in every view.

### 9.4 Restricting Recursion

Open recursion enables DNS amplification attacks:

```c
options {
    recursion yes;
    allow-recursion { 192.168.0.0/16; 10.0.0.0/8; localhost; };
};
```

```bash
dig @YOUR_SERVER_IP www.google.com   # Should fail from external
```

---



---

[← Previous](12-section-8-dnssec.md) | [↑ Index](index.md) | [Next →](14-section-10-logging.md)
