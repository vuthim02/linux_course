## 🔍 Section 7: Hubble

### What Is Hubble?

Hubble is a fully distributed networking and security observability platform built on top of Cilium and eBPF. It provides:

- **Flow logs** — every packet flow with metadata (source, dest, protocol, verdict, L7 info)
- **Service map** — real-time dependency graph of services
- **Metrics** — Prometheus metrics for network traffic
- **Cluster-wide visibility** — across all nodes without central aggregation

### Hubble Architecture

```
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ Node 1       │  │ Node 2       │  │ Node 3       │
│ Cilium Agent │  │ Cilium Agent │  │ Cilium Agent │
│ Hubble       │  │ Hubble       │  │ Hubble       │
│ Server       │  │ Server       │  │ Server       │
└──────┬───────┘  └──────┬───────┘  └──────┬───────┘
       │                  │                  │
       └──────────────────┼──────────────────┘
                          │
                    ┌─────▼──────┐
                    │  Hubble    │
                    │  Relay     │
                    │  (optional)│
                    └─────┬──────┘
                          │
              ┌───────────┴───────────┐
              │                       │
         ┌────▼────┐           ┌─────▼─────┐
         │  hubble  │           │ Hubble UI │
         │  CLI     │           │           │
         └─────────┘           └───────────┘
```

### Hubble CLI

```bash
# Install Hubble CLI
curl -L https://raw.githubusercontent.com/cilium/hubble/master/hubble/install.sh | bash

# Or download specific version
curl -Lo hubble-linux-amd64.tar.gz https://github.com/cilium/hubble/releases/latest/download/hubble-linux-amd64.tar.gz
tar xzvf hubble-linux-amd64.tar.gz
sudo mv hubble /usr/local/bin/

# Set up port-forward to Hubble Relay
cilium hubble enable
cilium hubble port-forward &

# Observe flows
hubble observe

# Observe flows from a specific namespace
hubble observe --namespace default

# Observe flows for a specific pod
hubble observe --pod frontend-xxxxx

# Observe flows with L7 information
hubble observe --protocol http

# Observe dropped packets
hubble observe --verdict DROPPED

# Observe flows to/from a service
hubble observe --service default/my-service

# JSON output for machine parsing
hubble observe -o json

# Follow mode (like tail -f)
hubble observe -f

# Filter by specific label
hubble observe --label app=frontend

# Show flows for the last 5 minutes
hubble observe --since 5m
```

### Hubble UI

```bash
# Enable Hubble UI
cilium hubble enable --ui

# Access UI
cilium hubble ui

# Or port-forward manually
kubectl -n kube-system port-forward service/hubble-ui 12000:80
# Open http://localhost:12000
```

The Hubble UI shows:
- **Service Map** — real-time graph of all pods and services, with traffic flows
- **Flow Details** — click any pod to see its traffic flows
- **Health Status** — node and cilium-agent health
- **Policies** — which policies are applied to which endpoints

### Service Map

The service map is a live dependency graph showing:

```
┌────────────┐     HTTP GET /api/v1/users     ┌────────────┐
│  frontend  │ ──────────────────────────────► │  api-server │
│  :3000     │                                  │  :8080      │
└────────────┘                                  └────────────┘
      │                                               │
      │ DNS lookup kube-dns:53                        │ Redis:6379
      ▼                                               ▼
┌────────────┐                                  ┌────────────┐
│  kube-dns  │                                  │  redis      │
└────────────┘                                  └────────────┘
```

```bash
# Dump service map as JSON
hubble observe -o json --since 1h > flows.json

# Count unique connections
hubble observe -o json | jq 'select(.l4) | "\\(.source.namespace)/\\(.source.pod_name) -> \\(.destination.namespace)/\\(.destination.pod_name) \\(.l4.TCP.destination_port)"' | sort -u
```

### Metrics

Hubble exports Prometheus metrics:

```bash
# Default metrics endpoints
kubectl -n kube-system port-forward service/hubble-metrics 9091

# Available metrics
curl http://localhost:9091/metrics | grep hubble
```

Key metrics:
- `hubble_flows_processed_total` — total flows by type, verdict, protocol
- `hubble_drop_total` — dropped packet count by reason
- `hubble_tcp_flags_total` — TCP flag distribution
- `hubble_http_requests_total` — HTTP request count by method, path, code
- `hubble_http_duration_seconds` — HTTP latency histogram

---



---

[← Previous](07-section-6-cilium-service-mesh.md) | [↑ Index](index.md) | [Next →](09-section-8-wireguard.md)
