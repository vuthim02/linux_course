## 4. kubectl Essentials

### Resource Inspection

```bash
# List resources
kubectl get pods
kubectl get pods -o wide          # with node and IP
kubectl get pods -o yaml          # full spec
kubectl get pods --watch          # stream changes
kubectl get deployments -A       # all namespaces
kubectl get all -n production    # everything in namespace

# Describe (detailed status, events, conditions)
kubectl describe pod nginx-7f8b9c6d9-abc12

# Logs
kubectl logs nginx-7f8b9c6d9-abc12
kubectl logs nginx-7f8b9c6d9-abc12 -c sidecar    # specific container
kubectl logs nginx-7f8b9c6d9-abc12 --previous    # previous crashed instance
kubectl logs -l app=nginx --tail=100 -f          # all pods matching label

# Execute command in container
kubectl exec -it nginx-7f8b9c6d9-abc12 -- sh
kubectl exec deploy/nginx -- env                 # run in a pod from deployment

# Copy files
kubectl cp nginx-7f8b9c6d9-abc12:/etc/nginx/nginx.conf ./nginx.conf

# Port forward (tunnel to a pod)
kubectl port-forward svc/nginx 8080:80           # localhost:8080 → service:80
kubectl port-forward pod/nginx-7f8b9c6d9-abc12 8080:80
```

### Resource Management

```bash
# Apply (create/update from file or stdin)
kubectl apply -f deployment.yaml
kubectl apply -f .                               # whole directory
kubectl apply -f https://example.com/manifest.yaml

# Delete
kubectl delete -f deployment.yaml
kubectl delete pod nginx-7f8b9c6d9-abc12
kubectl delete pod --all                         # delete all pods in namespace

# Diff (dry-run with server-side validation)
kubectl diff -f deployment.yaml
kubectl apply -f deployment.yaml --server-side --field-manager=my-cm
```

### Context and Namespace Switching

```bash
# Current context
kubectl config current-context

# Switch namespace (without installing kubens)
kubectl config set-context --current --namespace=production

# Using kubectx / kubens
kubectx                                    # list contexts
kubectx prod-cluster                       # switch
kubens                                     # list namespaces
kubens production                          # switch namespace
```

### API Resources

```bash
# List all available resources
kubectl api-resources
kubectl api-resources --namespaced=true
kubectl api-resources --api-group=apps

# Get API versions
kubectl api-versions

# Explain a resource field
kubectl explain deployment.spec.template.spec.containers.resources
```

### Cluster Health

```bash
kubectl get nodes
kubectl describe node worker-1
kubectl top nodes                          # requires metrics-server
kubectl top pods -A
kubectl cluster-info
kubectl get events -A --sort-by='.lastTimestamp'
```





[← Previous](03-3-installation.md) | [↑ Index](index.md) | [Next →](05-5-pods.md)
