## 14. Documentation and Handover

### Architecture Diagram (PlantUML)

```plantuml
@startuml
!define AWSPUML https://raw.githubusercontent.com/awslabs/aws-icons-for-plantuml/v16.0/dist

!includeurl AWSPUML/AWSCommon.puml
!includeurl AWSPUML/NetworkingContentDelivery/AmazonRoute53.puml
!includeurl AWSPUML/NetworkingContentDelivery/AmazonCloudFront.puml
!includeurl AWSPUML/Compute/AmazonEKS.puml
!includeurl AWSPUML/Database/AmazonRDS.puml
!includeurl AWSPUML/Storage/AmazonS3.puml

title Capstone Production Infrastructure

actor User as "End User"

User -> AmazonRoute53: api.capstone.example.com
AmazonRoute53 -> AmazonCloudFront: DNS resolution
AmazonCloudFront -> ALB: HTTPS request

rectangle "VPC" {
  rectangle "Public Subnet AZ-A" {
    component ALB as "Application Load Balancer"
  }
  rectangle "Private Subnet AZ-A" {
    AmazonEKS as "EKS Cluster"
    component Ingress as "Ingress-Nginx"
    component API as "API Pods"
    component Cache as "ElastiCache Redis"
  }
  rectangle "Private Subnet AZ-B" {
    AmazonRDS as "RDS PostgreSQL"
  }
}

AmazonRDS <.. API: TCP 5432
Cache <.. API: TCP 6379

rectangle "Monitoring" {
  component Prom as "Prometheus"
  component Graf as "Grafana"
  component Loki as "Loki"
}

API ..> Prom: /metrics
Prom ..> Graf: datasource
Prom ..> Loki: logs

AmazonS3 as "S3 Static Assets"
AmazonCloudFront -> AmazonS3: static content

@enduml
```

### README Template

```markdown
# Capstone Production Platform




[← Previous](15-testing-the-system.md) | [↑ Index](index.md) | [Next →](17-quick-start.md)
