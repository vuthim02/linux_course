## 🔍 Section 8: Pacemaker Resources — Deep Dive

### Virtual IP — IPaddr2

```bash
crm configure primitive vip ocf:heartbeat:IPaddr2 \
    params ip=192.168.1.100 cidr_netmask=24 \
           nic=eth0:1 \
    op monitor interval=10s
```

When the active node fails, Pacemaker moves the VIP to the other node. The ARP table updates automatically (send_arp).

### Filesystem Resource

```bash
crm configure primitive fs ocf:heartbeat:Filesystem \
    params device=/dev/drbd/by-res/r0 \
           directory=/var/www \
           fstype=ext4 \
    op monitor interval=30s
```

### Apache Web Server

```bash
crm configure primitive apache ocf:heartbeat:apache \
    params configfile=/etc/httpd/conf/httpd.conf \
    op monitor interval=30s \
    op start timeout=60s \
    op stop timeout=60s
```

### Nginx

```bash
crm configure primitive nginx ocf:heartbeat:nginx \
    params configfile=/etc/nginx/nginx.conf \
    op monitor interval=30s
```

### PostgreSQL (pgsqlms Multi-State)

```bash
crm configure primitive pgsql ocf:heartbeat:pgsqlms \
    params pgctl=/usr/bin/pg_ctl \
           pgdata=/var/lib/pgsql/data \
           repuser=replicator \
    op monitor interval=30s role=Master \
    op monitor interval=60s role=Slave \
    op start timeout=120s \
    op stop timeout=120s

crm configure ms ms-pgsql pgsql \
    meta master-max=1 master-node-max=1 \
           clone-max=2 clone-node-max=1 notify=true
```

### MySQL/MariaDB Replication

```bash
crm configure primitive mysql ocf:heartbeat:mysql \
    params binary=/usr/bin/mysqld_safe \
           datadir=/var/lib/mysql \
           socket=/var/lib/mysql/mysql.sock \
    op monitor interval=30s
```

### Xen/VM Resources

```bash
crm configure primitive vm-web ocf:heartbeat:Xen \
    params xmfile=/etc/xen/web-vm.cfg \
           name=web-vm \
    op monitor interval=30s \
    meta migration-threshold=1
```

### Complete Web Cluster Example

```bash
crm configure <<EOF
primitive vip ocf:heartbeat:IPaddr2 \
    params ip=192.168.1.100 cidr_netmask=24 \
    op monitor interval=10s

primitive fs ocf:heartbeat:Filesystem \
    params device=/dev/drbd/by-res/r0 \
           directory=/var/www fstype=ext4 \
    op monitor interval=30s

primitive apache ocf:heartbeat:apache \
    params configfile=/etc/httpd/conf/httpd.conf \
    op monitor interval=30s

primitive dlm ocf:pacemaker:controld \
    op monitor interval=30s

primitive clvmd ocf:heartbeat:clvm \
    op monitor interval=30s

group web-services vip fs apache

colocation col-web-services inf: web-services dlm clvmd
order ord-dlm inf: dlm clvmd web-services

property stonith-enabled=true
property no-quorum-policy=freeze
EOF
```





[← Previous](08-section-7-quorum.md) | [↑ Index](index.md) | [Next →](10-section-9-cluster-filesystems.md)
