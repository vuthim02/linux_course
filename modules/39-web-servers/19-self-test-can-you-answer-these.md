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

---

*Previous → Part 38: Container Basics*
*Next → Part 40: Databases — MariaDB and PostgreSQL*

[← Previous](part38.md) | [Next →](part40.md)


---

[← Previous](18-whats-coming-in-part-40.md) | [↑ Index](index.md)
