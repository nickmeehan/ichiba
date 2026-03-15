# Terraform

Nimbus uses Terraform to define and manage all cloud infrastructure. The configuration is organized into reusable modules with environment-specific variable files. This document covers the module structure, state management, and change workflow.

## Module Structure

```
infrastructure/terraform/
  modules/
    eks/            # EKS cluster, node groups, IAM roles
    rds/            # PostgreSQL instances, parameter groups
    elasticache/    # Redis clusters
    s3/             # Storage buckets, lifecycle policies
    vpc/            # VPC, subnets, NAT gateways
    cloudfront/     # CDN distribution
    secrets/        # Secrets Manager resources
    monitoring/     # CloudWatch alarms, SNS topics
  environments/
    staging/
      main.tf       # Module composition for staging
      variables.tf  # Staging-specific values
      terraform.tfvars
    production/
      main.tf       # Module composition for production
      variables.tf  # Production-specific values
      terraform.tfvars
```

Each module is self-contained with its own `variables.tf`, `outputs.tf`, and `main.tf`. Modules are versioned using Git tags and referenced by tag in environment configurations.

## State Management

Terraform state is stored in an S3 backend with DynamoDB locking:

| Setting          | Value                                  |
|-----------------|----------------------------------------|
| Backend         | S3                                      |
| Bucket          | `nimbus-terraform-state`               |
| Key pattern     | `{environment}/terraform.tfstate`      |
| Region          | us-east-1                               |
| DynamoDB table  | `nimbus-terraform-locks`               |
| Encryption      | AES-256 (SSE-S3)                       |

State files are never committed to the repository. Access to the state bucket is restricted to the CI/CD pipeline service account and infrastructure engineers.

## Environment Separation

Staging and production use identical module definitions but with different variable values:

| Variable              | Staging        | Production      |
|----------------------|----------------|-----------------|
| `eks_node_count_min` | 2              | 3               |
| `eks_node_count_max` | 4              | 10              |
| `rds_instance_class` | db.t3.medium   | db.r6g.xlarge   |
| `redis_node_type`    | cache.t3.small | cache.r6g.large |
| `rds_multi_az`       | false          | true            |

## Change Workflow

Infrastructure changes follow this process:

1. **Branch**: Create a feature branch with the Terraform changes.
2. **Plan**: CI runs `terraform plan` for the affected environment and posts the plan output as a PR comment.
3. **Review**: A second engineer reviews the plan output, paying attention to resource destruction or replacement.
4. **Apply**: After PR approval, the apply runs automatically on merge to main (staging) or via manual approval (production).
5. **Verify**: Post-apply health checks confirm the infrastructure is functioning correctly.

## Drift Detection

A scheduled CI job runs `terraform plan` daily against each environment. If drift is detected (changes not reflected in the Terraform state), an alert is sent to the infrastructure team's Slack channel. Drift is investigated and either reconciled in Terraform or reverted manually.

## See Also

- [Kubernetes](./kubernetes.md) - EKS cluster managed by Terraform
- [Secrets](./secrets.md) - Secrets Manager resources in Terraform
- [Networking](./networking.md) - VPC and networking resources

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: Terraform version upgrades or module structure changes -->
