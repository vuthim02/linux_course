## 15. Command Reference

### Context and Configuration

| Command | Purpose |
|---|---|
| `kubectl config get-contexts` | List contexts |
| `kubectl config use-context <name>` | Switch context |
| `kubectl config set-context --current --namespace=<ns>` | Set default namespace |
| `kubectl config view` | Show merged kubeconfig |
| `kubectl config current-context` | Show active context |

### Resource Management

| Command | Purpose |
|---|---|
| `kubectl apply -f <file>` | Create/update resources |
| `kubectl delete -f <file>` | Delete resources |
| `kubectl delete pod --all` | Delete all pods in ns |
| `kubectl diff -f <file>` | Show diff before applying |
| `kubectl edit deployment/nginx` | Edit live resource |

### Inspection

| Command | Purpose |
|---|---|
| `kubectl get pods -o wide` | List pods with node/IP |
| `kubectl get pods --watch` | Stream pod changes |
| `kubectl describe pod <name>` | Detailed pod status |
| `kubectl get events` | Show events |
| `kubectl api-resources` | List all resource types |
| `kubectl explain pod.spec` | Field documentation |

### Debugging

| Command | Purpose |
|---|---|
| `kubectl logs <pod>` | Container logs |
| `kubectl logs <pod> --previous` | Previous crash logs |
| `kubectl logs -l app=nginx -f` | Follow logs from multiple pods |
| `kubectl exec -it <pod> -- sh` | Shell into container |
| `kubectl cp <pod>:<src> <dest>` | Copy from pod |
| `kubectl port-forward svc/nginx 8080:80` | Tunnel to service |
| `kubectl debug <pod> -it --image=busybox` | Debug pod |
| `kubectl debug node/<name> -it --image=alpine` | Debug node |
| `kubectl top pod` | Show pod metrics |
| `kubectl top node` | Show node metrics |

### Workloads

| Command | Purpose |
|---|---|
| `kubectl scale deployment/nginx --replicas=5` | Scale deployment |
| `kubectl set image deployment/nginx nginx=nginx:1.26` | Update image |
| `kubectl rollout status deployment/nginx` | Check rollout |
| `kubectl rollout history deployment/nginx` | Show revisions |
| `kubectl rollout undo deployment/nginx` | Rollback to previous |
| `kubectl rollout undo deployment/nginx --to-revision=2` | Rollback to revision 2 |
| `kubectl rollout pause deployment/nginx` | Pause rollout |
| `kubectl rollout resume deployment/nginx` | Resume rollout |

### Cluster Administration

| Command | Purpose |
|---|---|
| `kubectl cordon <node>` | Mark unschedulable |
| `kubectl drain <node> --ignore-daemonsets` | Evict pods gracefully |
| `kubectl uncordon <node>` | Mark schedulable |
| `kubectl taint node <node> key=value:Effect` | Apply taint |
| `kubectl label node <node> key=value` | Add/update label |
| `kubectl cluster-info` | Show cluster info |
| `kubectl auth can-i <verb> <resource>` | Check permissions |

### Storage

| Command | Purpose |
|---|---|
| `kubectl get pv` | List persistent volumes |
| `kubectl get pvc` | List persistent volume claims |
| `kubectl get sc` | List storage classes |
| `kubectl describe pv <name>` | PV details |

### RBAC

| Command | Purpose |
|---|---|
| `kubectl create serviceaccount <name>` | Create SA |
| `kubectl create role <name> --verb=get,list --resource=pods` | Create Role |
| `kubectl create rolebinding <name> --role=<role> --serviceaccount=<ns>:<sa>` | Bind Role to SA |
| `kubectl create clusterrolebinding <name> --clusterrole=view --user=<user>` | Bind ClusterRole to user |
| `kubectl auth can-i get pods --as=system:serviceaccount:ns:sa` | Test permissions |





[← Previous](14-14-deep-understanding.md) | [↑ Index](index.md) | [Next →](16-16-15-hands-on-practices.md)
