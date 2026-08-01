## 🔍 Section 6: Vault in Production

### HA with Integrated Raft

```
┌──────────┐    ┌──────────┐    ┌──────────┐
│ Vault    │◄──►│ Vault    │◄──►│ Vault    │
│ Node 1   │    │ Node 2   │    │ Node 3   │
│ (leader) │    │(follower)│    │(follower)│
└────┬─────┘    └────┬─────┘    └────┬─────┘
     │               │               │
     └───────┬───────┴───────┬───────┘
             │ Load Balancer │
             └───────────────┘
```

Config (each node):
```hcl
storage "raft" {
  path = "/opt/vault/data"
  node_id = "node-1"
  retry_join { leader_api_addr = "http://node-1:8200" }
  retry_join { leader_api_addr = "http://node-2:8200" }
  retry_join { leader_api_addr = "http://node-3:8200" }
}
listener "tcp" { address = "0.0.0.0:8200"; tls_disable = true }
api_addr = "http://node-1:8200"
cluster_addr = "http://node-1:8201"
```

```
vault operator init -key-shares=5 -key-threshold=3               # init leader
vault operator raft join http://<leader>:8200                    # join followers
vault operator raft list-peers                                    # verify cluster
vault operator raft snapshot save /backups/vault-$(date +%F).snap # backup
```

### Performance Standby Nodes (Enterprise)

Handle read requests locally, forward writes to active node. Reduces latency for geo-distributed reads.

### Audit Devices

Log every request/response. Always enable in production.

```
vault audit enable file file_path=/var/log/vault/audit.log
vault audit enable syslog facility=AUTH tag=vault-audit
vault audit enable socket address=siem.example.com:514 socket_type=tcp
vault audit list
vault audit disable file/
```

Audit log entries show HMAC-hashed tokens and sensitive data:
```json
{
  "time": "2025-06-24T12:00:00Z",
  "type": "response",
  "auth": { "client_token": "hmac-sha256:abc...", "policies": ["my-policy"] },
  "request": { "operation": "read", "path": "database/creds/my-app-role" }
}
```

### Replication (Enterprise)

- **Performance Replication:** All data from primary → secondary clusters. Writes on primary, reads anywhere.
- **DR Replication:** Data replicated for DR. Secondary stays offline until promoted.





[← Previous](06-section-5-vault-policies.md) | [↑ Index](index.md) | [Next →](08-section-7-vault-agent-and-sidecar.md)
