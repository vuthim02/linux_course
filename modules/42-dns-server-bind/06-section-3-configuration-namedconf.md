## ⚙️ Section 3: Configuration — named.conf

### 3.1 The `options` Block

Defined in `/etc/bind/named.conf.options`:

```c
options {
    directory "/var/cache/bind";

    listen-on port 53 {
        192.168.1.10;
        10.0.0.1;
    };
    listen-on-v6 { none; };

    allow-query {
        192.168.0.0/16;
        10.0.0.0/8;
        localhost;
    };

    allow-recursion {
        192.168.0.0/16;
        10.0.0.0/8;
        localhost;
    };

    recursion yes;

    forwarders { 8.8.8.8; 1.1.1.1; };
    forward first;
    // "first" = try forwarders, then recurse
    // "only" = always use forwarders

    dnssec-validation auto;

    allow-transfer { none; };
    allow-update { none; };
    allow-notify { none; };

    rate-limit {
        responses-per-second 5;
        queries-per-second 10;
        slip 2;
    };

    max-cache-size 256m;
    recursive-clients 10000;
    tcp-clients 100;
};
```

### 3.2 Key Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `listen-on` | `{ any; }` | IPs and ports to bind |
| `allow-query` | `{ any; }` | Clients permitted to query |
| `allow-recursion` | `{ any; }` | Clients permitted to recurse |
| `allow-transfer` | `{ any; }` | Servers permitted to receive transfers |
| `recursion` | `yes` | Perform recursive resolution |
| `forwarders` | none | Upstream resolvers |
| `dnssec-validation` | `yes` | DNSSEC validation mode |
| `max-cache-size` | 90% RAM | Max DNS cache memory |
| `recursive-clients` | 1000 | Max simultaneous recursive queries |
| `rate-limit` | unlimited | Query rate limiting |
| `querylog` | `no` | Log every query |

### 3.3 Logging Configuration

```c
logging {
    channel default_log {
        file "/var/log/named/default.log" versions 3 size 10m;
        severity info;
        print-time yes;
        print-severity yes;
        print-category yes;
    };

    channel queries_file {
        file "/var/log/named/queries.log" versions 3 size 50m;
        severity info;
        print-time yes;
    };

    channel security_log {
        file "/var/log/named/security.log" versions 3 size 10m;
        severity info;
        print-time yes;
    };

    category default { default_log; };
    category security { security_log; };
    category queries { queries_file; };
    category xfer-in { default_log; };
    category xfer-out { default_log; };
    category notify { default_log; };
    category dnssec { default_log; };
    category lame-servers { default_log; };
    category network { security_log; };
};
```

**Logging severities (ascending):** `debug(1–3)` → `informational` → `notice` → `warning` → `error` → `critical`

```bash
sudo mkdir -p /var/log/named && sudo chown bind:bind /var/log/named && sudo chmod 750 /var/log/named
```

---



---

[← Previous](05-level-2-intermediary-configuration-zones.md) | [↑ Index](index.md) | [Next →](07-section-4-zones.md)
