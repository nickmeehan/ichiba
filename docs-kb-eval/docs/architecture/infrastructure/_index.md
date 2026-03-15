# Infrastructure

This section documents the infrastructure that hosts the Nimbus platform, including container orchestration, infrastructure-as-code, networking, secrets management, and monitoring.

## Contents

### [Kubernetes](./kubernetes.md)
When you need to understand the cluster configuration, modify deployment manifests, adjust resource limits, or debug pod scheduling issues.

### [Terraform](./terraform.md)
When you are provisioning new cloud resources, modifying existing infrastructure, or need to understand how the Terraform state is managed and how changes are applied.

### [Networking](./networking.md)
When you need to understand the VPC layout, configure security groups, troubleshoot load balancer issues, or manage DNS and TLS certificates.

### [Secrets](./secrets.md)
When you are adding a new secret, rotating credentials, or need to understand how secrets are injected into application pods at runtime.

### [Monitoring](./monitoring.md)
When you are setting up new metrics, creating Grafana dashboards, configuring alerting rules, or investigating production incidents using observability data.

## See Also

- [System Design](../system-design.md) - How infrastructure supports the application architecture
- [Kubernetes](./kubernetes.md) - Deployment and scaling configuration
- [Getting Started](../../getting-started.md) - Local development (no infrastructure needed)

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: New infrastructure components are added or the hosting platform changes -->
