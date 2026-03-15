# Kubernetes

Nimbus runs on a managed Kubernetes cluster (EKS) with separate namespaces for staging and production environments. This document covers the cluster configuration, deployment strategy, and scaling policies.

## Cluster Configuration

| Setting              | Value                            |
|---------------------|----------------------------------|
| Provider            | Amazon EKS                        |
| Kubernetes Version  | 1.29                              |
| Node Instance Type  | m6i.xlarge (4 vCPU, 16 GB RAM)   |
| Node Count          | 3-10 (auto-scaled)                |
| Region              | us-east-1                         |

The cluster uses the EKS managed node group with Cluster Autoscaler enabled. Nodes are spread across three availability zones for high availability.

## Namespaces

| Namespace    | Purpose                          |
|-------------|----------------------------------|
| `nimbus-prod`| Production workloads             |
| `nimbus-staging`| Staging/QA environment        |
| `nimbus-system`| Platform tools (ingress, cert-manager) |
| `monitoring`| Prometheus, Grafana              |

## Deployments

Each application component runs as a separate Kubernetes Deployment:

| Deployment        | Replicas (prod) | CPU Request | Memory Request |
|------------------|-----------------|-------------|----------------|
| `api-server`     | 3-10 (HPA)     | 500m        | 512Mi          |
| `websocket-server`| 2-5 (HPA)     | 250m        | 256Mi          |
| `worker`         | 2-8 (KEDA)     | 500m        | 512Mi          |
| `frontend`       | 2               | 100m        | 128Mi          |

## Horizontal Pod Autoscaler (HPA)

The API server scales based on CPU utilization and custom metrics:

```yaml
metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Pods
    pods:
      metric:
        name: http_request_duration_p99
      target:
        type: AverageValue
        averageValue: 500m
```

The worker deployment uses KEDA (Kubernetes Event-Driven Autoscaling) to scale based on BullMQ queue depth.

## Pod Disruption Budgets

To maintain availability during node maintenance and cluster upgrades:

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: api-server-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: api-server
```

At least 2 API server pods must remain available at all times.

## Resource Limits

Every container has resource requests and limits defined to prevent noisy-neighbor issues and ensure fair scheduling:

| Container    | CPU Limit | Memory Limit |
|-------------|-----------|--------------|
| api-server  | 1000m     | 1Gi          |
| worker      | 1000m     | 1Gi          |
| websocket   | 500m      | 512Mi        |
| frontend    | 200m      | 256Mi        |

Memory limits are enforced by the OOM killer. CPU limits use CFS throttling.

## Rolling Deployments

Deployments use the `RollingUpdate` strategy with `maxSurge: 1` and `maxUnavailable: 0`. This ensures that new pods are healthy before old pods are terminated. Readiness probes gate traffic to new pods until they pass health checks.

## See Also

- [Terraform](./terraform.md) - EKS cluster provisioning
- [Monitoring](./monitoring.md) - Cluster and pod metrics
- [System Design](../system-design.md) - Application components deployed here

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: Kubernetes version upgrades or deployment configuration changes -->
