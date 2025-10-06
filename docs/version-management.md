# Version Management and Updates

This document describes the version management approach for the OpenTelemetry and observability helm charts used in this repository.

## Current Versions

As of the latest update, the following chart versions are deployed:

| Component | Chart Version | Source Repository | Commit SHA |
|-----------|--------------|-------------------|------------|
| OpenTelemetry Collector | 0.136.1 | [open-telemetry/opentelemetry-helm-charts](https://github.com/open-telemetry/opentelemetry-helm-charts) | `aa53c03c65d68241c360a4a37f132fdb12a646f1` |
| OpenTelemetry Collector Image | 0.114.0 | `otel/opentelemetry-collector-contrib` | `sha256:6ab78adda9a0b877ba55fd18e07a8c9f4d39e20ae906c9a3c79c36f37d49e7f7` |
| Prometheus | 27.39.0 | [prometheus-community/helm-charts](https://github.com/prometheus-community/helm-charts) | `325265f34bed0b897a914dc05deb06243112902c` |
| Grafana | 10.0.0 | [grafana/helm-charts](https://github.com/grafana/helm-charts) | `43cde6d2b74f7b8e76ba6e23fda51508f6e82476` |
| Grafana Tempo | 1.23.3 | [grafana/helm-charts](https://github.com/grafana/helm-charts) | `f12ed84c9a2408a430da94c6c944392bf7eae840` |
| Grafana Loki | 6.42.0 | [grafana/helm-charts](https://github.com/grafana/helm-charts) | Release: `helm-loki-6.42.0` |

## SHA Pinning Strategy

### Why SHA Pinning?

SHA pinning provides several security and operational benefits:

1. **Reproducibility**: Ensures the exact same artifacts are deployed across environments
2. **Supply Chain Security**: Protects against tampering with upstream chart repositories
3. **Audit Trail**: Clear record of what was deployed and when
4. **Rollback Safety**: Can confidently roll back to known-good versions

### Implementation

This repository uses two complementary approaches for version pinning:

#### 1. Chart Verification with Cosign

All Helm charts include `verify.provider: cosign` configuration:

```yaml
chart:
  spec:
    chart: opentelemetry-collector
    version: 0.136.1
    sourceRef:
      kind: HelmRepository
      name: open-telemetry
    verify:
      provider: cosign  # Verifies chart signatures
```

This instructs Flux to verify the chart signature before deployment using [Sigstore Cosign](https://docs.sigstore.dev/cosign/overview/).

#### 2. Container Image SHA256 Digest Pinning

For container images, we use SHA256 digest pinning:

```yaml
image:
  repository: otel/opentelemetry-collector-contrib
  tag: 0.114.0@sha256:6ab78adda9a0b877ba55fd18e07a8c9f4d39e20ae906c9a3c79c36f37d49e7f7
```

The format `<version>@sha256:<digest>` ensures that:
- The human-readable version tag is preserved for clarity
- The exact image content is cryptographically verified

## How to Update Versions

### Prerequisites

- Git access to the upstream chart repositories
- kubectl with access to check compatibility
- Understanding of breaking changes in new versions

### Step-by-Step Update Process

#### 1. Identify Latest Stable Versions

Check the upstream repositories for the latest stable releases:

```bash
# OpenTelemetry Collector
git ls-remote --tags https://github.com/open-telemetry/opentelemetry-helm-charts.git | \
  grep "opentelemetry-collector-" | grep -v "\^{}" | sort -V | tail -5

# Prometheus
git ls-remote --tags https://github.com/prometheus-community/helm-charts.git | \
  grep "prometheus-2" | grep -v "\^{}" | sort -V | tail -5

# Grafana charts
git ls-remote --tags https://github.com/grafana/helm-charts.git | \
  grep -E "(grafana-[0-9]|tempo-[0-9])" | grep -v "\^{}" | sort -V | tail -10
```

#### 2. Get Commit SHAs for Target Versions

For each version you want to upgrade to, get the commit SHA:

```bash
# Example for OpenTelemetry Collector 0.136.1
git ls-remote --tags https://github.com/open-telemetry/opentelemetry-helm-charts.git | \
  grep "opentelemetry-collector-0.136.1" | grep -v "\^{}"
```

This will output: `<commit-sha>  refs/tags/opentelemetry-collector-0.136.1`

#### 3. Get Container Image Digests

For container images, retrieve the SHA256 digest:

```bash
# Using docker/podman
docker pull otel/opentelemetry-collector-contrib:0.114.0
docker inspect otel/opentelemetry-collector-contrib:0.114.0 | \
  jq -r '.[0].RepoDigests[0]'

# Using crane (recommended)
crane digest otel/opentelemetry-collector-contrib:0.114.0
```

#### 4. Review Breaking Changes

Before updating, review the release notes and changelogs:

- [OpenTelemetry Collector Releases](https://github.com/open-telemetry/opentelemetry-collector-contrib/releases)
- [Prometheus Chart Releases](https://github.com/prometheus-community/helm-charts/releases)
- [Grafana Helm Charts Releases](https://github.com/grafana/helm-charts/releases)

Pay special attention to:
- Configuration schema changes
- Deprecated features
- Required migration steps
- Breaking API changes

#### 5. Update Chart Versions

Update the helm release YAML files:

**OpenTelemetry Collector** (`apps/opentelemetry/1.0/otel-collector-helm.yaml`):
```yaml
chart:
  spec:
    chart: opentelemetry-collector
    version: <new-version>  # e.g., 0.136.1
    sourceRef:
      kind: HelmRepository
      name: open-telemetry
    verify:
      provider: cosign

values:
  image:
    repository: otel/opentelemetry-collector-contrib
    tag: <new-version>@sha256:<digest>  # e.g., 0.114.0@sha256:...
```

**Prometheus** (`apps/edge-observability/1.0/prometheus-helm.yaml`):
```yaml
chart:
  spec:
    chart: prometheus
    version: <new-version>  # e.g., 27.39.0
    sourceRef:
      kind: HelmRepository
      name: prometheus-community
    verify:
      provider: cosign
```

**Grafana, Tempo, Loki** (`apps/edge-observability/1.0/grafana-helm.yaml`):
```yaml
chart:
  spec:
    chart: <chart-name>  # grafana, tempo, or loki
    version: <new-version>
    sourceRef:
      kind: HelmRepository
      name: grafana
    verify:
      provider: cosign
```

#### 6. Update This Documentation

Update the version table at the top of this document with:
- New chart versions
- New commit SHAs
- New container image digests
- Date of update

#### 7. Test in Development Environment

Before committing to main:

1. Deploy to a development cluster
2. Verify all components start successfully
3. Check for configuration warnings or errors
4. Validate observability data flows correctly
5. Test dashboards and queries

#### 8. Commit and Document Changes

Create a clear commit message and PR description documenting:
- Which versions were updated
- Why (security fixes, new features, etc.)
- Any breaking changes or migration steps
- Testing performed

Example commit message:
```
Update OpenTelemetry and observability helm charts to latest versions

- OpenTelemetry Collector: 0.108.0 → 0.136.1
- Prometheus: 25.4.0 → 27.39.0
- Grafana: 7.0.2 → 10.0.0
- Tempo: 1.7.0 → 1.23.3
- Loki: 5.36.3 → 6.42.0

All charts now include cosign verification and SHA pinning
for enhanced security and reproducibility.
```

## Troubleshooting

### Chart Signature Verification Fails

If cosign verification fails:

1. Check that the chart repository supports cosign signatures
2. Verify the Flux version supports cosign (v2.0.0+)
3. Check Flux controller logs: `kubectl logs -n flux-system -l app=helm-controller`

### Image Pull Fails with Digest

If image pull fails with digest pinning:

1. Verify the digest is correct: `crane digest <image>:<tag>`
2. Check that the registry supports digest pulls
3. Ensure the image hasn't been removed from the registry

### Configuration Compatibility Issues

If the deployment fails after version update:

1. Review the chart's breaking changes documentation
2. Check for deprecated configuration options
3. Compare your values with the new chart's default values
4. Use `helm template` to preview generated manifests

## References

- [Flux Helm Release Documentation](https://fluxcd.io/flux/components/helm/helmreleases/)
- [Cosign Verification in Flux](https://fluxcd.io/flux/components/source/helmrepositories/#verification)
- [OpenTelemetry Collector Documentation](https://opentelemetry.io/docs/collector/)
- [Prometheus Operator Documentation](https://prometheus-operator.dev/)
- [Grafana Documentation](https://grafana.com/docs/)
