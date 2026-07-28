## 3. Installation

### kubeadm — Production-Grade Cluster Setup

kubeadm is the standard tool for bootstrapping Kubernetes clusters conforming to best practices.

**Prerequisites:**
- 2+ machines (Ubuntu 22.04+/Debian 12+/RHEL 9+) with 2+ CPU, 2+ GB RAM each
- Unique hostname, MAC address, product_uuid per machine
- Ports open: 6443 (API), 2379-2380 (etcd), 10250 (kubelet), 10259 (scheduler), 10257 (controller), 30000-32767 (NodePort)

**Install kubeadm, kubelet, kubectl (both nodes):**

```bash
# Ubuntu / Debian
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# Enable containerd
sudo systemctl enable --now containerd
```

**Initialize the control plane (control-plane node only):**

```bash
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

# Output includes:
# kubeadm join 192.168.1.10:6443 --token xxxxx --discovery-token-ca-cert-hash sha256:xxxxx
# Copy the admin config
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

**Join worker nodes:**

```bash
# On each worker node
sudo kubeadm join 192.168.1.10:6443 --token xxxxx --discovery-token-ca-cert-hash sha256:xxxxx
```

**Regenerate join token if lost:**

```bash
kubeadm token create --print-join-command
```

### CNI Plugin — Pod Networking

After `kubeadm init`, no pods can communicate until a CNI plugin is installed.

**Calico (recommended for production):**

```bash
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27/manifests/calico.yaml

# Verify
kubectl get pods -n calico-system
kubectl get nodes   # should show Ready
```

**Flannel (simple overlay):**

```bash
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```

**Cilium (advanced, eBPF-based):**

```bash
helm repo add cilium https://helm.cilium.io/
helm install cilium cilium/cilium --namespace kube-system --set podNetwork=10.244.0.0/16
```

### kubeconfig and kubectl Context

```bash
# Default location
~/.kube/config

# Multiple clusters in one file
kubectl config get-contexts
kubectl config use-context my-cluster
kubectl config set-context my-cluster --namespace=production

# Merge kubeconfigs
export KUBECONFIG=~/.kube/config:/path/to/other-config
kubectl config view --flatten > merged-config
```

### minikube — Local Testing

```bash
minikube start --cpus=4 --memory=8g --driver=kvm2
minikube stop
minikube delete
```

### kind — Kubernetes in Docker (for CI)

```bash
kind create cluster --name test
kind get clusters
kind delete cluster --name test

# Multi-node cluster with config
cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
EOF
```





[← Previous](02-2-architecture-deep-dive.md) | [↑ Index](index.md) | [Next →](04-4-kubectl-essentials.md)
