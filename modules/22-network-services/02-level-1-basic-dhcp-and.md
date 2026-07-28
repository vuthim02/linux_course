## ⭐ Level 1: Basic — DHCP and HTTP Basics

![DHCP interaction — Discover, Offer, Request, Acknowledge](https://upload.wikimedia.org/wikipedia/commons/5/58/DHCP_session.svg)

*DHCP session flow — Discover, Offer, Request, Acknowledge (Wikimedia Commons / public domain)*

> **Level 1 Goal:** Set up a DHCP server to assign IP addresses automatically and configure a basic Apache or Nginx web server to serve static content.

### What You'll Cover
- DHCP lease process: Discover, Offer, Request, Acknowledge (DORA)
- Installing and configuring `isc-dhcp-server`
- Defining subnet ranges, static reservations, and lease times
- Installing Apache2/Nginx and serving a default page
- Listening on ports: checking with `ss -tlnp`

### Why This Level Matters

DHCP and HTTP are the bread and butter of network services. DHCP automatically assigns IP addresses to devices on your network. Without it, you would manually configure every laptop, phone, and server that connects. HTTP is how the world serves web content. Even if you are not a web developer, every sysadmin needs to set up and maintain a web server at some point.

The DORA process (Discover, Offer, Request, Acknowledge) is how DHCP works under the hood. Understanding it helps you debug why a device is not getting an IP address. Is the broadcast not reaching the server? Is the offer being rejected? Is the lease expiring too quickly?

### What You'll Practice

- Installing `isc-dhcp-server` and configuring a subnet range
- Creating static reservations so specific devices always get the same IP
- Installing Apache2 and Nginx, then serving a test page
- Using `ss -tlnp` to verify which ports your services are listening on

> 💡 Always check `ss -tlnp` after starting a service. If the port is not open, the service did not start correctly. This single command saves more debugging time than any other.





[← Previous](01-what-you-will-achieve-in.md) | [↑ Index](index.md) | [Next →](03-section-1-dhcp-server.md)
