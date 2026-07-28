## 8. Secrets and Configuration

### External Secrets Operator

```bash
helm repo add external-secrets https://charts.external-secrets.io
helm repo update

helm upgrade --install external-secrets external-secrets/external-secrets \
  --namespace external-secrets \
  --create-namespace \
  --set installCRDs=true \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=arn:aws:iam::ACCOUNT_ID:role/external-secrets-role
```

### SecretStore — AWS Secrets Manager

```yaml
# helm/templates/externalsecret.yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: {{ include "capstone.fullname" . }}
spec:
  provider:
    aws:
      service: SecretsManager
      region: {{ .Values.awsRegion }}
      auth:
        jwt:
          serviceAccountRef:
            name: {{ include "capstone.serviceAccountName" . }}
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: {{ include "capstone.fullname" . }}-db
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: {{ include "capstone.fullname" . }}
    kind: SecretStore
  target:
    name: {{ include "capstone.fullname" . }}-db
    creationPolicy: Owner
  data:
    - secretKey: database-url
      remoteRef:
        key: capstone-database-credentials
        property: connection_string
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: {{ include "capstone.fullname" . }}-redis
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: {{ include "capstone.fullname" . }}
    kind: SecretStore
  target:
    name: {{ include "capstone.fullname" . }}-redis
    creationPolicy: Owner
  data:
    - secretKey: redis-url
      remoteRef:
        key: capstone-redis-credentials
        property: connection_string
```

### ConfigMap for App Configuration

```yaml
# helm/templates/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "capstone.fullname" . }}-config
  labels:
    {{- include "capstone.labels" . | nindent 4 }}
data:
  LOG_LEVEL: {{ .Values.config.LOG_LEVEL | quote }}
  MAX_ITEMS: {{ .Values.config.MAX_ITEMS | quote }}
  CACHE_TTL: {{ .Values.config.CACHE_TTL | quote }}
  {{- if .Values.config.extra }}
  {{- toYaml .Values.config.extra | nindent 2 }}
  {{- end }}
```





[← Previous](07-7-database-and-stateful-services.md) | [↑ Index](index.md) | [Next →](09-9-observability-stack.md)
