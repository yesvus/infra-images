# Pin upstream official Actions runner; add only tools required by existing
# publish/migration/release jobs. Target: ARM64 ARC runner Pods in Kubernetes.
FROM ghcr.io/actions/actions-runner@sha256:e5496277be5d09bc968b3d64911b74e219ac4a3f2edce956a3ecf9271bea1ef4

USER root
ARG TARGETARCH=arm64
ARG KUBECTL_VERSION=v1.36.4

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends gh ca-certificates; \
    rm -rf /var/lib/apt/lists/*; \
    curl -fsSL -o /usr/local/bin/kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${TARGETARCH}/kubectl"; \
    curl -fsSL -o /tmp/kubectl.sha256 "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${TARGETARCH}/kubectl.sha256"; \
    printf '%s  %s\n' "$(cat /tmp/kubectl.sha256)" /usr/local/bin/kubectl | sha256sum --check --status; \
    chmod 0755 /usr/local/bin/kubectl; \
    rm -f /tmp/kubectl.sha256

# Existing staging script invokes "k3s kubectl" on Gurbet. The runner needs
# only the kubectl client, not host k3s access. Preserve CLI compatibility.
RUN printf '%s\n' '#!/bin/sh' 'if [ "$1" = kubectl ]; then shift; exec /usr/local/bin/kubectl "$@"; fi' 'echo "Only k3s kubectl is available in CI" >&2' 'exit 1' > /usr/local/bin/k3s && chmod 0755 /usr/local/bin/k3s

USER runner
