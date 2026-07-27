## 🧠 Deep Understanding

### Forward Proxy vs Reverse Proxy at the HTTP Level

**Forward proxy** changes the HTTP request fundamentally. When a client uses a forward proxy, it sends requests like:

```
GET http://example.com/path HTTP/1.1
Host: example.com
```

Note the **absolute URI** in the request line (`http://example.com/path` instead of `/path`). This is required by RFC 7230 for proxy requests. The proxy then:
1. Parses the absolute URI to determine the origin server
2. Resolves DNS for the server (on behalf of the client)
3. Opens a new TCP connection to the server
4. Forwards the request (possibly modified)
5. Returns the response to the client

For HTTPS, the client sends a `CONNECT` request to establish a tunnel:

```
CONNECT example.com:443 HTTP/1.1
Host: example.com
```

The proxy opens the TCP connection to the target and then proxies raw bytes bidirectionally. The proxy **cannot inspect** HTTPS traffic (unless it does SSL bump/MITM).

**Reverse proxy** receives standard HTTP requests:

```
GET /path HTTP/1.1
Host: example.com
```

The reverse proxy:
1. Accepts the TCP connection from the client
2. Terminates TLS (if HTTPS)
3. Looks at the `Host` header and/or URL path
4. Selects a backend server based on its routing rules
5. Opens a new TCP connection to the backend (possibly with different protocol)
6. Forwards the request (adding X-Forwarded-For, modifying Host, etc.)
7. Optionally caches the response
8. Returns the response to the client

**Key architectural difference:** A forward proxy requires **client cooperation** (explicit proxy config or transparent interception). A reverse proxy is **transparent to the client** — the client does not know it exists.

### How Squid Processes a Request

```
1. TCP accept
       │
2. Parse request (absolute URI or CONNECT)
       │
3. ACL chain evaluation (top to bottom)
       │
       ├──► DENY: Send error response (403), log, close
       │
4. Authentication (if configured)
       │
       ├──► 407 Proxy Authentication Required → client retries with credentials
       │
5. DNS resolution of the destination
       │
6. Connection to origin server (or cache_peer / parent proxy)
       │
7. Cache lookup
       │
       ├──► HIT (fresh): Serve from cache
       │
       ├──► STALE: Conditional GET (If-Modified-Since / ETag)
       │         ├──► 304 Not Modified → refresh TTL, serve cached
       │         └──► 200 → replace cache, serve new
       │
       └──► MISS: Forward to origin
       │
8. Receive response from origin
       │
9. Cache decision (cacheable? → store in cache_dir + cache_mem)
       │
10. Log the transaction (access.log)
       │
11. Send response to client
```

**ACL evaluation order:** Squid evaluates ACLs in the order they appear in the config. The **first matching `http_access allow` or `http_access deny`** wins. If no rule matches, Squid defaults to **deny**.

### How HAProxy's Event Loop Works

HAProxy uses a **single-threaded event-driven architecture** (multi-threading was introduced in v1.8+ but the event loop concept remains).

```
main loop:
  while (1):
    1. epoll_wait() / kqueue() / poll()
       └─► Returns list of ready file descriptors (FDs)
    
    2. For each ready FD:
       a. Accept new connection (if listener socket)
          ├─► Allocate task (stream interface)
          ├─► Insert into run queue
          └─► Set up connection structure
    
       b. Process incoming data (if client/server socket)
          ├─► Read data into buffer
          ├─► Parse protocol (HTTP/tcp)
          ├─► Apply ACLs / rules
          └─► Queue outgoing data
    
    3. Run task scheduler:
       └─► Process tasks from run queue:
           ├─► Health checks (check timers)
           ├─► Stick-table maintenance (expire entries)
           ├─► Stats page updates
           └─► Connection retries
    
    4. Send pending data:
       └─► splice() / sendfile() for zero-copy forwarding
```

**Zero-copy forwarding:** HAProxy uses `splice()` (Linux) or `sendfile()` to move data between file descriptors **without copying to userspace**:

```
Client socket ──splice()──► Backend socket (or vice versa)
```

This means HAProxy can forward traffic at **near line rate** with minimal CPU usage. The data never touches HAProxy's application buffers — it goes directly from the network card's DMA buffer to the outgoing socket.

**Multi-threading (HAProxy 1.8+):**

```
Thread 0 (main):
    ├─► epoll FD
    ├─► Accept incoming connections
    └─► Distribute across threads (via queue)

Thread 1..N (workers):
    ├─► Run their own epoll instance
    ├─► Process their own connections (no lock contention)
    └─► Share stick-tables via atomic operations
```

HAProxy uses **lock-free data structures** for most shared state (stick-tables, server state). Each connection is pinned to a single thread after accept, so there is no contention on connection processing.

### How PROXY Protocol Preserves Client IP Through Multiple Hops

Without PROXY protocol, each proxy in a chain would see the IP of the **previous hop**:

```
Client (1.2.3.4) ──► HAProxy1 ──► HAProxy2 ──► Backend
   conn src: 1.2.3.4    conn src: 10.0.0.1    conn src: 10.0.0.2
```

The backend sees 10.0.0.2 as the client IP, not 1.2.3.4.

With PROXY protocol:

```
Client (1.2.3.4) ──► HAProxy1 ──► HAProxy2 ──► Backend

TCP connect:           PROXY header:           PROXY header:
  src: 1.2.3.4          "1.2.3.4, 53456,       "1.2.3.4, 53456,
                        10.0.0.1, 443"         10.0.0.1, 443"

After receiving PROXY header:
  HAProxy1 stores client IP: 1.2.3.4
  HAProxy2 replaces connection source with client IP from header
  Backend sees source IP: 1.2.3.4
```

**The process:**

1. **HAProxy1** accepts client TCP connection (src=1.2.3.4, dst=10.0.0.1:443)
2. **HAProxy1** opens connection to HAProxy2 and prepends PROXY v2 header:
   ```
   \x0D\x0A\x0D\x0A\x00\x0D\x0A\x51\x55\x49\x54\x0A...
   src_addr=1.2.3.4 src_port=53456 dst_addr=10.0.0.1 dst_port=443
   ```
3. **HAProxy2** receives the connection, reads the PROXY header, and **replaces** the transport-level source address with the address from the PROXY header
4. **HAProxy2** then forwards the actual TLS/HTTP data without further modification

This works because PROXY protocol is at the **transport layer** — there is no concept of "HTTP request" in PROXY v1/v2. It is simply a preamble before the real connection data, regardless of whether the connection carries HTTP, SMTP, MySQL, or raw TCP.

---



---

[← Previous](18-15-hands-on-practices.md) | [↑ Index](index.md) | [Next →](20-command-reference.md)
