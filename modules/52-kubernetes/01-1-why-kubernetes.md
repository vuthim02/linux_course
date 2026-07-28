## 1. Why Kubernetes?

You already run containers. You have a Docker Compose file on a single host. That works until:
- The host dies and your database goes with it.
- You need to scale the web tier to 50 replicas across 10 machines.
- You need to roll out a new version without dropping a single request.
- You need to discover services without hardcoded IPs.

Kubernetes solves all of these. It is a **container orchestrator** — a platform that automates deployment, scaling, and operations of application containers across clusters of machines.

### What Kubernetes Gives You

| Capability | What It Means |
|---|---|
| **Self-healing** | Containers that crash are restarted. Nodes that die have their workloads rescheduled elsewhere. |
| **Scaling** | Manual `kubectl scale` or automatic Horizontal Pod Autoscaler based on CPU/memory/custom metrics. |
| **Service discovery & load balancing** | Every pod gets a stable DNS name thru Services. Traffic is load-balanced across healthy pods. |
| **Rolling updates & rollbacks** | Deployments let you update pods incrementally with zero downtime. Failed rollouts roll back automatically (or manually). |
| **Portability** | Same manifests work on-prem, AWS EKS, GCP GKE, Azure AKS, minikube, kind, k3s, OpenShift. |
| **Declarative configuration** | You write YAML files describing desired state. Kubernetes reconciles actual state to match. |

### Cluster Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                   Control Plane                      │
│  ┌──────────┐  ┌──────────┐  ┌───────────────────┐ │
│  │  etcd    │  │ API      │  │ Controller        │ │
│  │ (state)  │◄─►│ Server   │◄─►│ Manager           │ │
│  └──────────┘  └────┬─────┘  └───────────────────┘ │
│                     │                               │
│  ┌──────────────────▼────────────────────────────┐  │
│  │            kube-scheduler                      │  │
│  └───────────────────────────────────────────────┘  │
└────────────────────────┬────────────────────────────┘
                         │
    ┌────────────────────┼────────────────────┐
    │                    │                    │
┌───▼──────────┐  ┌─────▼────────┐  ┌───────▼────────┐
│  Worker 1    │  │  Worker 2    │  │  Worker N      │
│ ┌──────────┐ │  │ ┌──────────┐ │  │ ┌──────────┐   │
│ │ kubelet  │ │  │ │ kubelet  │ │  │ │ kubelet  │   │
│ │ kube-proxy│ │  │ │ kube-proxy│ │  │ │ kube-proxy│  │
│ │ containerd│ │  │ │ containerd│ │  │ │ containerd│  │
│ │ Pods ▲▼  │ │  │ │ Pods ▲▼  │ │  │ │ Pods ▲▼  │   │
│ └──────────┘ │  │ └──────────┘ │  │ └──────────┘   │
└───────────────┘  └──────────────┘  └────────────────┘
```

The **control plane** makes decisions. **Workers** run the actual workloads. All communication flows through the API server — nothing talks to etcd directly except the API server.





[↑ Index](index.md) | [Next →](02-2-architecture-deep-dive.md)
