## 6. Dockerfile

### Key Instructions

```dockerfile
# FROM — base image
FROM alpine:3.19

# LABEL — metadata
LABEL maintainer="admin@example.com"
LABEL version="1.0"

# RUN — execute commands in a new layer
RUN apk update && apk add --no-cache python3 py3-pip

# COPY — copy files from build context
COPY app.py /app/

# ADD — copy with URL/tar auto-extraction
ADD https://example.com/file.tar.gz /tmp/
ADD archive.tar.gz /tmp/

# ENV — environment variables
ENV PYTHONUNBUFFERED=1
ENV APP_HOME=/app

# WORKDIR — set working directory
WORKDIR /app

# EXPOSE — document port (does NOT publish)
EXPOSE 8080

# USER — run as non-root
RUN adduser -D appuser
USER appuser

# CMD — default command (can be overridden)
CMD ["python3", "app.py"]

# ENTRYPOINT — fixed command (args are appended)
ENTRYPOINT ["python3"]

# HEALTHCHECK — check container health
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD curl -f http://localhost:8080/ || exit 1

# VOLUME — declare mount point
VOLUME /data

# STOPSIGNAL
STOPSIGNAL SIGTERM
```

### CMD vs ENTRYPOINT

| Form | Override with CLI |
|------|------------------|
| `CMD ["cmd", "arg"]` | `docker run image new_cmd` |
| `ENTRYPOINT ["cmd"]` | `docker run --entrypoint new_cmd image` |
| `ENTRYPOINT ["cmd"]` + `CMD ["arg"]` | `docker run image arg` (appends to ENTRYPOINT) |

```dockerfile
# Exec form (preferred — JSON array)
CMD ["nginx", "-g", "daemon off;"]

# Shell form (wraps in /bin/sh -c)
CMD nginx -g "daemon off;"
```

### Multi-Stage Builds

```dockerfile
# Stage 1: Build
FROM golang:1.22 AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o server .

# Stage 2: Runtime
FROM alpine:3.19
RUN apk add --no-cache ca-certificates
COPY --from=builder /app/server /usr/local/bin/server
EXPOSE 8080
USER nobody
CMD ["server"]
```

Benefits:
- Final image is tiny (no build tools)
- Build cache for dependencies
- Multiple stages can use different base images

### .dockerignore

```
node_modules/
.git/
*.log
.DS_Store
dist/
```





[← Previous](08-5-images.md) | [↑ Index](index.md) | [Next →](10-7-containers.md)
