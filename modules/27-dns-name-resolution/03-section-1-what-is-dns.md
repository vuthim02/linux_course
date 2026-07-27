## 🔍 Section 1: What Is DNS?

The Domain Name System (DNS) is the distributed directory that maps human-readable hostnames to machine-readable IP addresses.

### The Hierarchy

DNS is not a single database — it's a tree:

```
. (root)
├── com. (TLD)
│   ├── google.com.  (authoritative)
│   ├── github.com.  (authoritative)
│   └── example.com. (authoritative)
├── org. (TLD)
│   ├── wikipedia.org.
│   └── kernel.org.
├── net. (TLD)
├── uk. (country-code TLD)
├── de.
└── io.
```

Each level delegates authority to the next:

| Level | Who Runs It | Example |
|-------|-------------|---------|
| Root (`.`) | 13 root server operators (a.root-servers.net through m.root-servers.net) | 198.41.0.4 |
| TLD (`.com`, `.org`) | Registry operators (Verisign, PIR, etc.) | a.gtld-servers.net |
| Authoritative | Domain owner or DNS provider | ns1.google.com |
| Recursive Resolver | ISP, Google (8.8.8.8), Cloudflare (1.1.1.1) | 8.8.8.8 |

### Resolution Process — Step by Step

```
Query: What is the IP of www.example.com?

Step 1: Client asks local resolver (e.g., 8.8.8.8)
Step 2: Resolver asks root server: "Who manages .com?"
Step 3: Root server replies: "Ask a.gtld-servers.net"
Step 4: Resolver asks TLD server: "Who manages example.com?"
Step 5: TLD server replies: "Ask ns1.example.com"
Step 6: Resolver asks authoritative server: "What is www.example.com?"
Step 7: Authoritative server replies: "93.184.216.34"
Step 8: Resolver returns answer to client
```

```bash
# Trace this live with dig
dig +trace www.example.com
```

Output (abbreviated):
```
; <<>> DiG 9.18.19 <<>> +trace www.example.com
;; global options: +cmd
.            517796  IN  NS  m.root-servers.net.
.            517796  IN  NS  a.root-servers.net.
;; Received 262 bytes from 8.8.8.8#53(8.8.8.8) in 4 ms

com.            172800  IN  NS  a.gtld-servers.net.
com.            172800  IN  NS  b.gtld-servers.net.
;; Received 1182 bytes from 198.41.0.4#53(a.root-servers.net) in 12 ms

example.com.        172800  IN  NS  a.iana-servers.net.
example.com.        172800  IN  NS  b.iana-servers.net.
;; Received 410 bytes from 192.5.6.30#53(a.gtld-servers.net) in 16 ms

www.example.com.    86400   IN  A   93.184.216.34
;; Received 64 bytes from 199.43.0.53#53(b.iana-servers.net) in 20 ms
```

### Recursive vs Iterative Resolution

**Iterative:** The server responds with the best answer it already knows (referral). The client must follow the chain. This is what `dig +trace` does manually.

**Recursive:** The server does all the work — it follows referrals on behalf of the client. Your ISP's resolver (or 8.8.8.8) is a recursive resolver. The client makes one query and gets the final answer.

```
Client → Recursive Resolver (does all the work) → Root → TLD → Authoritative
                                                      ↓
Client ← Final answer ← Recursive Resolver ←←←←←←←←←←←
```

### Record Types

| Type | Full Name | Purpose | Example |
|------|-----------|---------|---------|
| A | Address record | Maps hostname to IPv4 | 93.184.216.34 |
| AAAA | IPv6 Address record | Maps hostname to IPv6 | 2606:2800:220:1:248:1893:25c8:1946 |
| CNAME | Canonical Name | Alias (one name → another name) | www → example.com |
| MX | Mail Exchange | Mail server for domain | mail.example.com |
| TXT | Text record | Arbitrary text (SPF, DKIM, verification) | "v=spf1 mx ~all" |
| NS | Nameserver | Authoritative nameserver | ns1.example.com |
| SOA | Start of Authority | Zone metadata (serial, refresh, retry) | — |
| PTR | Pointer record | Reverse DNS (IP → hostname) | 34.216.184.93.in-addr.arpa |

```bash
# Query each record type
dig A google.com
dig AAAA google.com
dig MX google.com
dig NS google.com
dig TXT google.com
dig SOA google.com

# Short form (just the answer)
dig +short A google.com
dig +short MX google.com

# Specific nameserver query
dig @8.8.8.8 google.com
```

---



---

[← Previous](02-level-1-basic-dns-fundamentals.md) | [↑ Index](index.md) | [Next →](04-section-2-etchosts-local-hostname.md)
