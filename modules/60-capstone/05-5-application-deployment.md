## 5. Application Deployment

### Sample Microservice — FastAPI Application

```python
# app/main.py
import os
import time
import uuid
from contextlib import asynccontextmanager

import asyncpg
import redis.asynced as aioredis
from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.httpx import HTTPXClientInstrumentor
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from prometheus_client import Counter, Histogram, generate_latest
from starlette.responses import Response

# Metrics
REQUEST_COUNT = Counter("app_requests_total", "Total requests", ["method", "endpoint", "status"])
REQUEST_DURATION = Histogram("app_request_duration_seconds", "Request duration in seconds",
                             ["method", "endpoint"], buckets=(0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10))
ERROR_COUNT = Counter("app_errors_total", "Total errors", ["method", "endpoint"])

pool = None
redis_client = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    global pool, redis_client
    pool = await asyncpg.create_pool(
        dsn=os.getenv("DATABASE_URL"),
        min_size=5,
        max_size=20,
        command_timeout=30,
    )
    redis_client = aioredis.from_url(
        os.getenv("REDIS_URL", "redis://localhost:6379/0"),
        max_connections=20,
        decode_responses=True,
    )
    tracer_provider = TracerProvider(
        resource=Resource.create({"service.name": "api-service"})
    )
    tracer_provider.add_span_processor(
        BatchSpanProcessor(OTLPSpanExporter(endpoint=os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT", "http://tempo:4318/v1/traces")))
    )
    trace.set_tracer_provider(tracer_provider)
    yield
    await pool.close()
    await redis_client.close()

app = FastAPI(title="Capstone API", version="1.0.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

FastAPIInstrumentor.instrument_app(app)
HTTPXClientInstrumentor().instrument()

@app.middleware("http")
async def metrics_middleware(request: Request, call_next):
    start = time.time()
    response = await call_next(request)
    duration = time.time() - start
    REQUEST_COUNT.labels(method=request.method, endpoint=request.url.path, status=response.status_code).inc()
    REQUEST_DURATION.labels(method=request.method, endpoint=request.url.path).observe(duration)
    if response.status_code >= 500:
        ERROR_COUNT.labels(method=request.method, endpoint=request.url.path).inc()
    return response

@app.get("/metrics")
async def metrics():
    return Response(content=generate_latest(), media_type="text/plain")

@app.get("/health")
async def health():
    try:
        async with pool.acquire() as conn:
            await conn.execute("SELECT 1")
        await redis_client.ping()
        return {"status": "healthy", "database": "connected", "cache": "connected"}
    except Exception as e:
        raise HTTPException(status_code=503, detail=str(e))

@app.get("/api/v1/items")
async def list_items():
    async with pool.acquire() as conn:
        rows = await conn.fetch("SELECT id, name, created_at FROM items ORDER BY created_at DESC LIMIT 100")
    return [dict(row) for row in rows]

@app.post("/api/v1/items")
async def create_item(name: str):
    item_id = str(uuid.uuid4())
    async with pool.acquire() as conn:
        await conn.execute("INSERT INTO items (id, name) VALUES ($1, $2)", item_id, name)
    await redis_client.set(f"item:{item_id}", name, ex=3600)
    return {"id": item_id, "name": name}

@app.get("/api/v1/items/{item_id}")
async def get_item(item_id: str):
    cached = await redis_client.get(f"item:{item_id}")
    if cached:
        return {"id": item_id, "name": cached, "source": "cache"}
    async with pool.acquire() as conn:
        row = await conn.fetchrow("SELECT id, name, created_at FROM items WHERE id = $1", item_id)
    if not row:
        raise HTTPException(status_code=404, detail="Item not found")
    await redis_client.set(f"item:{item_id}", row["name"], ex=3600)
    return {"id": row["id"], "name": row["name"], "source": "database"}
```

### Dockerfile — Multi-Stage Build

```dockerfile
# Dockerfile
FROM python:3.12-slim AS builder

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc libpq-dev && \
    rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt && \
    find /root/.local -name "*.pyc" -delete

FROM python:3.12-slim AS runtime

WORKDIR /app

RUN groupadd -r appuser && useradd -r -g appuser appuser && \
    apt-get update && apt-get install -y --no-install-recommends \
    libpq5 curl ca-certificates && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /root/.local /home/appuser/.local
COPY app/ .

ENV PATH=/home/appuser/.local/bin:$PATH \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

USER appuser

EXPOSE 8000

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4", "--limit-concurrency", "256"]
```

### requirements.txt

```txt
fastapi==0.115.0
uvicorn[standard]==0.30.6
asyncpg==0.29.0
redis[hiredis]==5.1.1
prometheus-client==0.20.0
opentelemetry-api==1.27.0
opentelemetry-sdk==1.27.0
opentelemetry-exporter-otlp-proto-http==1.27.0
opentelemetry-instrumentation-fastapi==0.48b0
opentelemetry-instrumentation-httpx==0.48b0
httpx==0.27.2
```

### Database Schema Migration (Alembic)

```python
# alembic/env.py
from logging.config import fileConfig
from alembic import context
import asyncpg
import os

config = context.config
fileConfig(config.config_file_name)

target_metadata = None

def run_migrations_online():
    connectable = asyncpg.create_pool(dsn=os.getenv("DATABASE_URL"))

    async def do_migrations():
        async with connectable.acquire() as conn:
            await conn.execute("""
                CREATE TABLE IF NOT EXISTS items (
                    id UUID PRIMARY KEY,
                    name VARCHAR(255) NOT NULL,
                    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
                );
                CREATE INDEX IF NOT EXISTS idx_items_created_at ON items(created_at DESC);
            """)

    import asyncio
    asyncio.run(do_migrations())

run_migrations_online()
```

### Helm Chart Structure

```
helm/
├── Chart.yaml
├── values.yaml
├── values-staging.yaml
├── values-prod.yaml
└── templates/
    ├── _helpers.tpl
    ├── deployment.yaml
    ├── service.yaml
    ├── ingress.yaml
    ├── hpa.yaml
    ├── pdb.yaml
    ├── servicemonitor.yaml
    ├── configmap.yaml
    └── externalsecret.yaml
```

### Helm Chart — Deployment

```yaml
# helm/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "capstone.fullname" . }}
  labels:
    {{- include "capstone.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount }}
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0
      maxSurge: 1
  selector:
    matchLabels:
      {{- include "capstone.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "capstone.selectorLabels" . | nindent 8 }}
        {{- if .Values.podLabels }}
        {{- toYaml .Values.podLabels | nindent 8 }}
        {{- end }}
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8000"
        prometheus.io/path: "/metrics"
        checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
    spec:
      {{- if .Values.serviceAccount.create }}
      serviceAccountName: {{ include "capstone.serviceAccountName" . }}
      {{- end }}
      securityContext:
        {{- toYaml .Values.podSecurityContext | nindent 8 }}
      terminationGracePeriodSeconds: 60
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
            - weight: 100
              podAffinityTerm:
                labelSelector:
                  matchExpressions:
                    - key: app.kubernetes.io/name
                      operator: In
                      values:
                        - {{ include "capstone.name" . }}
                topologyKey: topology.kubernetes.io/zone
      {{- if .Values.nodeSelector }}
      nodeSelector:
        {{- toYaml .Values.nodeSelector | nindent 8 }}
      {{- end }}
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - name: http
              containerPort: 8000
              protocol: TCP
          env:
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: {{ include "capstone.fullname" . }}-db
                  key: database-url
            - name: REDIS_URL
              valueFrom:
                secretKeyRef:
                  name: {{ include "capstone.fullname" . }}-redis
                  key: redis-url
            - name: OTEL_EXPORTER_OTLP_ENDPOINT
              value: {{ .Values.otelEndpoint | quote }}
            - name: OTEL_SERVICE_NAME
              value: {{ include "capstone.fullname" . }}
          envFrom:
            - configMapRef:
                name: {{ include "capstone.fullname" . }}-config
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
          livenessProbe:
            httpGet:
              path: /health
              port: http
            initialDelaySeconds: 10
            periodSeconds: 15
            timeoutSeconds: 5
            failureThreshold: 3
          readinessProbe:
            httpGet:
              path: /health
              port: http
            initialDelaySeconds: 5
            periodSeconds: 10
            timeoutSeconds: 3
            failureThreshold: 2
```

### Helm Chart — HPA

```yaml
# helm/templates/hpa.yaml
{{- if .Values.autoscaling.enabled }}
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ include "capstone.fullname" . }}
  labels:
    {{- include "capstone.labels" . | nindent 4 }}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ include "capstone.fullname" . }}
  minReplicas: {{ .Values.autoscaling.minReplicas }}
  maxReplicas: {{ .Values.autoscaling.maxReplicas }}
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
        - type: Pods
          value: 1
          periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
        - type: Percent
          value: 100
          periodSeconds: 15
        - type: Pods
          value: 4
          periodSeconds: 15
      selectPolicy: Max
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: {{ .Values.autoscaling.targetCPUUtilizationPercentage }}
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: {{ .Values.autoscaling.targetMemoryUtilizationPercentage }}
    {{- if .Values.autoscaling.customMetrics }}
    {{- toYaml .Values.autoscaling.customMetrics | nindent 4 }}
    {{- end }}
{{- end }}
```

### Helm Chart — PDB

```yaml
# helm/templates/pdb.yaml
{{- if .Values.pdb.enabled }}
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: {{ include "capstone.fullname" . }}
  labels:
    {{- include "capstone.labels" . | nindent 4 }}
spec:
  minAvailable: {{ .Values.pdb.minAvailable }}
  selector:
    matchLabels:
      {{- include "capstone.selectorLabels" . | nindent 6 }}
{{- end }}
```

### Helm Chart — Ingress

```yaml
# helm/templates/ingress.yaml
{{- if .Values.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "capstone.fullname" . }}
  labels:
    {{- include "capstone.labels" . | nindent 4 }}
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/use-regex: "true"
    nginx.ingress.kubernetes.io/rewrite-target: /$2
    {{- if .Values.ingress.certManager }}
    cert-manager.io/cluster-issuer: {{ .Values.ingress.certManager }}
    {{- end }}
    {{- if .Values.ingress.annotations }}
    {{- toYaml .Values.ingress.annotations | nindent 4 }}
    {{- end }}
spec:
  {{- if .Values.ingress.tls }}
  tls:
    {{- range .Values.ingress.tls }}
    - hosts:
        {{- range .hosts }}
        - {{ . | quote }}
        {{- end }}
      secretName: {{ .secretName }}
    {{- end }}
  {{- end }}
  rules:
    {{- range .Values.ingress.hosts }}
    - host: {{ .host | quote }}
      http:
        paths:
          {{- range .paths }}
          - path: {{ .path }}
            pathType: {{ .pathType }}
            backend:
              service:
                name: {{ include "capstone.fullname" $ }}
                port:
                  number: {{ $.Values.service.port }}
          {{- end }}
    {{- end }}
{{- end }}
```

### Helm Chart — ServiceMonitor

```yaml
# helm/templates/servicemonitor.yaml
{{- if .Values.serviceMonitor.enabled }}
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: {{ include "capstone.fullname" . }}
  labels:
    {{- include "capstone.labels" . | nindent 4 }}
    release: {{ .Values.serviceMonitor.release }}
spec:
  selector:
    matchLabels:
      {{- include "capstone.selectorLabels" . | nindent 6 }}
  endpoints:
    - port: http
      path: /metrics
      interval: {{ .Values.serviceMonitor.interval }}
      scrapeTimeout: {{ .Values.serviceMonitor.scrapeTimeout }}
  namespaceSelector:
    matchNames:
      - {{ .Release.Namespace }}
{{- end }}
```

### Helm Values

```yaml
# helm/values.yaml
replicaCount: 3

image:
  repository: ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/capstone-api
  tag: latest
  pullPolicy: IfNotPresent

serviceAccount:
  create: true
  name: ""

podSecurityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000
  seccompProfile:
    type: RuntimeDefault

resources:
  requests:
    cpu: 250m
    memory: 256Mi
  limits:
    cpu: 500m
    memory: 512Mi

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 20
  targetCPUUtilizationPercentage: 70
  targetMemoryUtilizationPercentage: 80

pdb:
  enabled: true
  minAvailable: 2

service:
  type: ClusterIP
  port: 80
  targetPort: 8000

ingress:
  enabled: true
  certManager: letsencrypt-prod
  hosts:
    - host: api.capstone.example.com
      paths:
        - path: /api(/|$)(.*)
          pathType: ImplementationSpecific
  tls:
    - hosts:
        - api.capstone.example.com
      secretName: api-tls

serviceMonitor:
  enabled: true
  release: kube-prometheus-stack
  interval: 15s
  scrapeTimeout: 10s

otelEndpoint: http://tempo.monitoring:4318/v1/traces

config:
  LOG_LEVEL: info
  MAX_ITEMS: 1000
  CACHE_TTL: 3600

nodeSelector:
  node-type: application
```

```yaml
# helm/values-prod.yaml
replicaCount: 5

autoscaling:
  minReplicas: 5
  maxReplicas: 30
  targetCPUUtilizationPercentage: 60
  targetMemoryUtilizationPercentage: 75

pdb:
  minAvailable: 3

resources:
  requests:
    cpu: 500m
    memory: 512Mi
  limits:
    cpu: 1000m
    memory: 1024Mi
```





[← Previous](04-4-kubernetes-cluster-setup.md) | [↑ Index](index.md) | [Next →](06-6-cicd-pipeline.md)
