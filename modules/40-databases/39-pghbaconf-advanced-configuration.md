## pg_hba.conf — Advanced Configuration

```conf
# TYPE    DATABASE    USER          ADDRESS          METHOD

# Trust local connections from postgres user
local    all         postgres                         peer

# Require SCRAM password for app users on local TCP
host     all         all           127.0.0.1/32      scram-sha-256

# Specific database for specific user from subnet
host     company     appuser       192.168.1.0/24    scram-sha-256

# Reject everyone else
host     all         all           0.0.0.0/0         reject

# SSL-only connections
hostssl  all         all           0.0.0.0/0         scram-sha-256

# Require SSL client certificate
hostssl  all         all           0.0.0.0/0         cert clientcert=1
```



---

[← Previous](38-role-attributes.md) | [↑ Index](index.md) | [Next →](40-pgidentconf-user-mapping.md)
