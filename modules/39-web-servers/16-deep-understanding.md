## 🧠 Deep Understanding

### Apache MPM Architectures

#### Prefork (Process per Request)

```
Connection arrives
    ↓
Parent process accepts connection
    ↓
Child process spawned (or reused from pool)
    ↓
Child handles entire request lifecycle
    ↓   (read request → process → send response)
Child returns to idle pool
```

**Why prefork exists:** The original Apache model. Each process has its own memory space, so a crash in one request doesn't affect others. Crucially, `mod_php` (libphp) is **not thread-safe** — it cannot run in a threaded MPM. Prefork is the only choice when using `mod_php`.

**Memory cost:** Each child process loads the full PHP interpreter, even when serving a static file. For 200 concurrent connections with prefork, you might use 200 × ~20MB = 4GB just for Apache children.

#### Worker (Threaded within Processes)

```
Connection arrives
    ↓
Process with available thread handles it
    ↓
Thread executes: read → process → send
    ↓
Thread returns to thread pool
```

**Why worker exists:** Reduces memory overhead by sharing memory across threads within a process. But threads share the same address space — a crash in one thread kills all threads in that process.

**Limitation:** Thread-safety issues. `mod_php` cannot be used. PHP-FPM (external FastCGI process manager) is required.

#### Event (Async-Ready)

```
Connection arrives
    ↓
Listener thread accepts, categorizes:
    ├── Idle keep-alive → handled by listener (no worker thread tied up)
    └── Active request  → passed to a worker thread
                            ↓
                         Worker processes, returns to pool
```

**The key insight:** With HTTP keep-alive, a connection can stay open for seconds or minutes while the client sends no data. In prefork/worker, that connection **holds a process/thread hostage** doing nothing. The event MPM's listener thread handles all idle connections, and only passes active requests to workers.

**Scaling:** Event MPM can handle 10,000+ concurrent connections with modest memory because only actively-processing requests occupy threads.

### Nginx Event Loop

Nginx uses a completely different architecture: **single-threaded event loop** per worker process.

```
Nginx Worker Process:
┌──────────────────────────────────────────────────┐
│   while (1) {                                    │
│       events = epoll_wait()  ← Block until I/O   │
│       for each event:                            │
│           if new connection:                     │
│               accept() → add to epoll            │
│           if readable:                           │
│               read request → process → queue response│
│           if writable:                           │
│               send response data                 │
│   }                                              │
└──────────────────────────────────────────────────┘
```

This is the **reactor pattern**:
1. Register file descriptors (connections) with epoll
2. Call `epoll_wait()` — kernel tells you which fds are ready
3. Process only ready fds
4. Repeat

**Why this is fast:**
- No thread/process per connection overhead
- No context switching between threads
- No memory wasted on idle connections
- A single worker can handle 10,000+ connections because most connections are idle (waiting for client data) and cost almost nothing
- Only CPU cache working set of one thread matters (no cache thrashing from multiple threads)

### Linux I/O Multiplexing: epoll vs select vs poll

| Mechanism | Complexity | Scaling | Key Limitation |
|-----------|-----------|---------|----------------|
| `select()` | O(n) | Poor | Max 1024 fds, scans all fds every call |
| `poll()` | O(n) | Poor | Scans all fds every call |
| `epoll` | O(1) | Excellent | Linux-only, returns only ready fds |

**How epoll works:**

```c
// 1. Create epoll instance
int epfd = epoll_create1(0);

// 2. Add file descriptors to monitor
struct epoll_event ev;
ev.events = EPOLLIN | EPOLLET;  // Edge-triggered
ev.data.fd = client_socket;
epoll_ctl(epfd, EPOLL_CTL_ADD, client_socket, &ev);

// 3. Wait for events (efficient!)
struct epoll_event events[1024];
int n = epoll_wait(epfd, events, 1024, -1);

// 4. Process only ready fds
for (int i = 0; i < n; i++) {
    handle_event(events[i].data.fd);
}
```

With `select()`, the kernel scans all 10,000 fds to find the 3 that are ready. With `epoll`, the kernel returns only the 3 ready ones. This is O(1) vs O(n) — the difference between handling 10 connections and 100,000 connections.

Nginx uses **edge-triggered epoll** (`EPOLLET`) — it gets notified only when new data arrives, not repeatedly for existing data.

### PHP-FPM Integration

PHP-FPM (FastCGI Process Manager) is a separate process manager for PHP that runs **outside** the web server.

```
Apache (event MPM)          Nginx (event loop)
       │                           │
       │  FastCGI protocol          │  FastCGI protocol
       ▼                           ▼
┌──────────────── PHP-FPM ──────────────────┐
│  Master process                            │
│  ├── Pool: www                             │
│  │   ├── child 1 (PHP process, idle)       │
│  │   ├── child 2 (PHP process, busy)       │
│  │   ├── child 3 (PHP process, busy)       │
│  │   └── ... (pm.max_children)             │
│  ├── Pool: admin                           │
│  │   └── ...                               │
│  └── Pool: custom pools                    │
└────────────────────────────────────────────┘
```

**How a PHP request flows:**

```
1. Nginx receives HTTP request
2. Nginx matches location ~ \.php$
3. Nginx sends FastCGI request to PHP-FPM socket
4. PHP-FPM master picks an idle child process
5. PHP child sets SCRIPT_FILENAME, runs the PHP file
6. PHP child returns response via FastCGI to Nginx
7. Nginx sends HTTP response to client
8. PHP child returns to idle pool
```

**PHP-FPM pool configuration** (`/etc/php/8.3/fpm/pool.d/www.conf`):

```ini
[www]
pm = dynamic                        # dynamic, static, ondemand
pm.max_children = 50                # Max PHP processes
pm.start_servers = 5                # Number to start
pm.min_spare_servers = 5            # Keep at least this many idle
pm.max_spare_servers = 35           # Keep at most this many idle
pm.max_requests = 500               # Restart after N requests (memory leak protection)

; Listen on Unix socket (faster) or TCP
listen = /run/php/php8.3-fpm.sock
; listen = 127.0.0.1:9000
```

**pm = dynamic** (most common): FPM adjusts children based on demand.
**pm = static**: Fixed number of children always running.
**pm = ondemand**: Spawn children only when needed, kill idle ones (memory saving).

### sendfile and Zero-Copy

Normal file serving without sendfile:

```
Userspace (nginx)                 Kernel
┌─────────────┐            ┌──────────────┐
│ read()      │ ◄───────  │ Disk → Page  │ ← Copy 1: disk to kernel buffer
│ buffer      │            │ Cache        │
│             │            │              │
│ write()     │ ────────► │ Socket       │ ← Copy 2: kernel buffer to socket
└─────────────┘            └──────────────┘
```

Data goes: `Disk → Kernel buffer → Userspace buffer → Kernel socket buffer → Network`

Two copies through memory, one through userspace that the CPU must handle.

With `sendfile()`:

```
Userspace (nginx)                 Kernel
┌─────────────┐            ┌──────────────┐
│ sendfile()  │ ────────► │ Disk → Socket │ ← Zero copies through userspace
│ (tells      │            │ (DMA transfer)│    Data goes directly from
│  kernel to  │            │               │    disk page cache to NIC
│  send file) │            │               │
└─────────────┘            └──────────────┘
```

Data goes: `Disk Page Cache → NIC (via DMA)` — CPU never touches the data.

**What about the page cache?** The file is first read from disk into the kernel's page cache (if not already there). But this happens via DMA (Direct Memory Access) — the disk controller writes data to RAM directly without CPU involvement. Then `sendfile()` sends that cached data to the network, again via DMA if possible.

For large files, `sendfile()` with `directio` can bypass the page cache entirely to avoid evicting hot cache entries.

### Apache mod_php vs PHP-FPM

| Aspect | mod_php (prefork) | PHP-FPM |
|--------|-------------------|---------|
| Architecture | PHP interpreter embedded in Apache child | Separate PHP process pool |
| Memory | Each Apache child loads PHP (20-40MB each) | PHP processes shared via pool |
| Concurrency | One process per request (prefork only) | Reusable PHP pool, handles many requests |
| File permissions | Runs as www-data (Apache user) | Can run as different user per pool |
| Configuration | PHP config in apache (`php_flag`, `php_value`) | Separate php.ini per pool |
| Performance | Slower, higher memory | Faster, lower memory, scalable |
| Compatibility | Widest (all PHP apps work) | Nearly all PHP apps work |





[← Previous](15-practice-section-15-hands-on-exercises.md) | [↑ Index](index.md) | [Next →](17-command-reference.md)
