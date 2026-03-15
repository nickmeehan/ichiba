# Networking

This document describes the network architecture for the Nimbus platform, covering the VPC layout, security groups, load balancing, CDN configuration, and DNS management.

## VPC Layout

The production VPC uses a three-tier subnet architecture across three availability zones:

| Subnet Type | CIDR Range       | Purpose                                      |
|------------|------------------|----------------------------------------------|
| Public     | 10.0.0.0/22      | Load balancers, NAT gateways                 |
| Private    | 10.0.16.0/20     | Application pods (EKS nodes)                 |
| Isolated   | 10.0.32.0/22     | RDS, ElastiCache (no internet access)        |

Each subnet type has one subnet per availability zone (3 AZs in us-east-1). The VPC CIDR is `10.0.0.0/16`, leaving room for future expansion.

NAT gateways in each AZ provide outbound internet access for the private subnets. Isolated subnets have no route to the internet and are accessed only from the private subnets.

## Security Groups

| Security Group          | Inbound Rules                                  | Purpose              |
|------------------------|-------------------------------------------------|----------------------|
| `alb-sg`              | 443 from 0.0.0.0/0                              | Public load balancer |
| `eks-nodes-sg`        | All from `alb-sg`, all from self                 | Application pods     |
| `rds-sg`              | 5432 from `eks-nodes-sg`                         | PostgreSQL           |
| `redis-sg`            | 6379 from `eks-nodes-sg`                         | Redis/ElastiCache    |
| `elasticsearch-sg`    | 9200 from `eks-nodes-sg`                         | Elasticsearch        |

Security groups follow the principle of least privilege. No security group allows SSH access from the public internet.

## Load Balancer

The Application Load Balancer (ALB) handles all inbound traffic:

| Setting            | Value                                    |
|-------------------|-----------------------------------------|
| Type              | Application Load Balancer (ALB)          |
| Scheme            | Internet-facing                          |
| Listeners         | HTTPS (443) only                         |
| Certificate       | ACM-managed wildcard `*.nimbus.app`      |
| Target groups     | API server pods, frontend pods           |
| Health check path | `/health` (API), `/` (frontend)          |
| Idle timeout      | 120 seconds (for WebSocket connections)  |

Path-based routing directs `/api/*` to the API server target group and all other paths to the frontend target group.

## CDN (CloudFront)

Static frontend assets are served through CloudFront:

| Setting           | Value                                     |
|------------------|--------------------------------------------|
| Origin           | S3 bucket `nimbus-frontend-assets`          |
| Cache behavior   | Cache immutable assets (hashed filenames)   |
| TTL              | 1 year for hashed assets, 5 min for index.html |
| Compression      | Gzip and Brotli                             |
| Price class      | PriceClass_100 (US, Canada, Europe)         |

## DNS Management

DNS is managed through Route 53:

| Record                  | Type  | Target                          |
|------------------------|-------|----------------------------------|
| `nimbus.app`           | A     | CloudFront distribution           |
| `*.nimbus.app`         | CNAME | ALB DNS name                      |
| `api.nimbus.app`       | CNAME | ALB DNS name                      |

Workspace subdomains (`acme.nimbus.app`) resolve through the wildcard CNAME to the ALB, where the Host header determines the tenant.

## TLS Certificates

TLS certificates are issued and renewed automatically by AWS Certificate Manager (ACM). The wildcard certificate `*.nimbus.app` covers all workspace subdomains. Certificate renewal happens 60 days before expiration with no manual intervention required.

## See Also

- [Kubernetes](./kubernetes.md) - Pod networking within the cluster
- [Terraform](./terraform.md) - VPC and networking resources as code
- [Secrets](./secrets.md) - TLS certificate management

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: VPC CIDR changes, new security groups are added, or CDN configuration changes -->
