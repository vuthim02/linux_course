## 📝 Self-Test — Can You Answer These?
1. What is the difference between Apache prefork, worker, and event MPM? Which one supports mod_php?
2. What does the `sendfile()` system call do and why is it faster than standard file serving?
3. How does Nginx handle thousands of concurrent connections with so few processes?
4. In Nginx, what is the difference between `location /`, `location = /`, and `location ~ \.php$`?
5. What does the `try_files $uri $uri/ /index.html` directive do?
6. Name three load balancing methods in Nginx's upstream module.
7. What is OCSP stapling and why does it matter for TLS performance?
8. How does `.htaccess` work in Apache, and why doesn't Nginx support it?
9. What is the difference between `proxy_pass` in Nginx and `ProxyPass` in Apache?
10. How would you configure HSTS and what does the `preload` directive do?
11. What is `epoll` and how does it differ from `select()`?
12. How does PHP-FPM integrate with Nginx? Why can't you use `mod_php` with Nginx?
13. What is the purpose of `MaxRequestWorkers` in Apache and `worker_connections` in Nginx?
14. You deploy Nginx → Apache reverse proxy. Nginx serves static files directly. Why is this architecture beneficial?
15. What log format would you use to capture response times in Apache? How do you find the slowest requests?
**Score:** 12/15 correct = ready for Part 40.
## Answer Key
### Q1: What is the difference between Apache prefork, worker, and event MPM?
**Answer:** Prefork = process per connection (supports mod_php). Worker = threads per process. Event = handles idle connections asynchronously (best for high concurrency). Only prefork supports mod_php.
### Q2: What does `sendfile()` do and why is it faster?
**Answer:** Zero-copy file transfer — data goes from kernel page cache directly to the socket without copying through userspace. Much faster than read-then-write.
### Q3: How does Nginx handle thousands of concurrent connections?
**Answer:** Event-driven, asynchronous architecture. A few worker processes handle all connections via epoll, avoiding per-connection thread/process overhead.
### Q4: What is the difference between `location /`, `location = /`, and `location ~ \.php$`?
**Answer:** `location /` = prefix match (any URI starting with /). `location = /` = exact match (only "/"). `location ~ \.php$` = regex match (URIs ending in .php).
### Q5: What does `try_files $uri $uri/ /index.html` do?
**Answer:** Tries to serve the exact file, then directory, then falls back to `/index.html` (useful for SPA routing).
### Q6: Name three Nginx load balancing methods.
**Answer:** `round-robin` (default), `least_conn` (fewest active connections), `ip_hash` (sticky sessions by IP).
### Q7: What is OCSP stapling and why does it matter?
**Answer:** Nginx fetches the TLS certificate's OCSP response and "staples" it to the TLS handshake. Clients don't need to contact the CA separately, reducing latency and improving privacy.
### Q8: Why doesn't Nginx support .htaccess?
**Answer:** Nginx uses a centralized config for performance (no per-request filesystem checks). Apache reads .htaccess per request, which adds overhead.
### Q9: What is the difference between `proxy_pass` (Nginx) and `ProxyPass` (Apache)?
**Answer:** Functionally similar — both forward requests to a backend server. Nginx uses `proxy_pass` in location blocks. Apache uses `ProxyPass` directives in config.
### Q10: How do you configure HSTS and what does `preload` do?
**Answer:** `Strict-Transport-Security: max-age=31536000; includeSubDomains; preload`. Preload submits the domain to browser HSTS preload lists, enforcing HTTPS before first visit.
### Q11: What is `epoll` vs `select()`?
**Answer:** `select` = O(n) — checks all file descriptors each call. `epoll` = O(1) — uses event-driven callbacks, only returns active FDs. Scales to millions of connections.
### Q12: How does PHP-FPM integrate with Nginx?
**Answer:** Nginx passes PHP requests to PHP-FPM via FastCGI protocol (`fastcgi_pass`). mod_php doesn't work with Nginx because Nginx has no module system for PHP embedding.
### Q13: What is MaxRequestWorkers and worker_connections?
**Answer:** `MaxRequestWorkers` (Apache) = max simultaneous requests. `worker_connections` (Nginx) = max connections per worker process. Total Nginx capacity = workers × connections.
### Q14: Why is Nginx → Apache reverse proxy beneficial?
**Answer:** Nginx handles static files fast (sendfile) and absorbs slow clients. Apache focuses on dynamic content (PHP, Python) behind the proxy.
### Q15: How do you capture response times in Apache?
**Answer:** Use `LogFormat "%D ..." combined` with `%D` (microseconds). Find slowest: `awk '{print $NF}' access.log | sort -rn | head`.
*Previous → Part 38: Container Basics*
*Next → Part 40: Databases — MariaDB and PostgreSQL*
[← Previous](18-whats-coming-in-part-40.md) | [↑ Index](index.md)
