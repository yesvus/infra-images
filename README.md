# infra-images

Public, reproducible container image build recipes with isolated smoke tests.
This repository intentionally contains **no** private infra inventory, cluster
access, authentication files, OpenBao policy, GitHub credentials, or deployment manifests.

| Name | Platform | Purpose |
| --- | --- | --- |
| infra-arc-runner | linux/arm64 | Ephemeral Actions runner with kubectl + gh |
| infra-arc-opencode | linux/amd64 | Ephemeral Actions runner with OpenCode |
| infra-tezgah | linux/arm64 | Non-root development toolchain with SSH and code-server |

## Delivery contract
- GitHub-hosted native-architecture jobs compile and smoke-test PRs; PR tokens
  have read-only repo access, **no package write**, no secrets or kubeconfig.
- The manual "Publish image" workflow can run only by yesvus on main; it
  rebuilds and smokes **before** registry auth, publishes a SHA tag and reports a digest.
- Publishing never deploys to Kubernetes. GHCR package visibility and private
  cluster image pulls are separate from the public source repository.
- The private `yesvus/ops` repo remains the source of truth for Kubernetes
  configuration; existing pinned digests stay unchanged until a separate ops PR.
- No Git history or configuration was copied from the private repo. Only the
  reviewed source files required to build these generic images were imported.

From the repo root on a native Linux runner with Docker and Buildx:
```bash
bash scripts/build-smoke.sh arc-runner
bash scripts/build-smoke.sh arc-opencode
bash scripts/build-smoke.sh tezgah
```

Image recipes and test scripts are MIT-licensed. Dependencies retain their own licenses.
