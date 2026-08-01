## ✅ Self-Test
Answer these 15 questions. **Score:** 12/15 correct = ready for Part 46.
### Question 1
Which HTTP method does a forward proxy use to establish an HTTPS tunnel?
```
A) GET
B) POST
C) CONNECT
D) TUNNEL
```
### Question 2
What is the key difference between a forward proxy and a reverse proxy?
```
A) Forward proxy uses TCP; reverse proxy uses UDP
B) Forward proxy is configured on the client side; reverse proxy is deployed on the server side
C) Forward proxy can only cache; reverse proxy can only load balance
D) There is no difference — they are the same thing
```
### Question 3
In Squid, which directive defines the storage location and size of the disk cache?
```
A) cache_mem
B) cache_dir
C) cache_storage
D) disk_cache
```
### Question 4
What does the `visible_hostname` directive do in Squid?
```
A) Sets the hostname that Squid binds to
B) Sets the hostname Squid reports in error pages and Via headers
C) Sets the DNS hostname of the origin server
D) Sets the admin contact email
```
### Question 5
In Nginx, what does `proxy_set_header X-Real-IP $remote_addr;` do?
```
A) Sets the real IP of the backend server
B) Passes the client's real IP to the backend
C) Sets the proxy's own IP address
D) Verifies the client's IP against a whitelist
```
### Question 6
Which Nginx upstream directive provides consistent session persistence based on the client IP?
```
A) least_conn
B) ip_hash
C) random
D) round_robin
```
### Question 7
In HAProxy, what is the purpose of the `stick-table` directive?
```
A) To define which servers are available
B) To create a table mapping client attributes to backend servers for session persistence
C) To stick a server to a specific port
D) To configure sticky timeouts for health checks
```
### Question 8
What does `option forwardfor` do in HAProxy?
```
A) Forwards the request to a different backend
B) Adds the X-Forwarded-For header with the client IP
C) Forwards the connection immediately without buffering
D) Enables fast-forward mode for TCP
```
### Question 9
Which of the following is NOT a valid cache status in Nginx?
```
A) HIT
B) MISS
C) STALE
D) FORWARD
```
### Question 10
What is the PROXY protocol used for?
```
A) To encrypt traffic between proxies
B) To preserve the original client IP across multiple proxy hops
C) To proxy FTP connections through HTTP
D) To authenticate clients to the proxy
```
### Question 11
In Squid, what is the purpose of `refresh_pattern`?
```
A) To automatically refresh the Squid configuration file
B) To control how Squid determines if a cached object is fresh enough to serve
C) To refresh the DNS cache
D) To periodically rotate the log files
```
### Question 12
Which HAProxy algorithm sends requests to the server with the fewest active connections?
```
A) roundrobin
B) leastconn
C) source
D) uri
```
### Question 13
How does a transparent proxy differ from a standard forward proxy?
```
A) Transparent proxy does not cache content
B) Transparent proxy operates without client-side configuration using network interception
C) Transparent proxy only works with HTTPS
D) Transparent proxy requires authentication by default
```
### Question 14
What Linux syscall does HAProxy use for zero-copy data forwarding?
```
A) recv()
B) send()
C) splice()
D) mmap()
```
### Question 15
In a multi-tier proxy architecture (HAProxy → Nginx → Backend), how should backend servers retrieve the true client IP?
```
A) From $remote_addr (Nginx) and src IP (HAProxy)
B) From the X-Forwarded-For header added by HAProxy, with set_real_ip_from configured on Nginx
C) Randomly guess from the available headers
D) The true client IP is lost and cannot be recovered
```
**Score:** 12/15 correct = ready for Part 46.
**Answers:** 1-C, 2-B, 3-B, 4-B, 5-B, 6-B, 7-B, 8-B, 9-D, 10-B, 11-B, 12-B, 13-B, 14-C, 15-B
*Previous → Part 44: Mail Servers — Postfix*
*Next → Part 46: Monitoring and Alerting*
[← Previous](21-whats-coming-in-part-46.md) | [↑ Index](index.md)
