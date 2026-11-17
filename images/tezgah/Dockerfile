# Versioned ARM64 development toolchain; no source or credentials in image.
FROM node:24-bookworm-slim@sha256:dc26ae92c9fb15cf6b1d63e20f0944b2efe0f115b20e00be48fb23fceb061c54

# renovate: datasource=npm depName=@opencode/cli
ARG OPENCODE_VERSION=2.3.0
# renovate: datasource=npm depName=@openai/codex
ARG CODEX_VERSION=0.169.0
# renovate: datasource=npm depName=@anthropic-ai/claude-code
ARG CLAUDE_CODE_VERSION=2.1.325
# renovate: datasource=github-releases depName=google-antigravity/antigravity-cli
ARG AGY_VERSION=1.5.9
ARG AGY_ARM64_SHA256=3a18c238c7ee6661e43df7e824a7d4c1bed78aeeda09430921a0f1dbfe825bca
# renovate: datasource=github-releases depName=coder/code-server extractVersion=^v(?<version>.*)$
ARG CODE_SERVER_VERSION=4.145.2
ARG CODE_SERVER_ARM64_SHA256=e867a34416e2da4a83496b09580001893e7a4e5bb58a0624c4fcd22819e7d53d

LABEL org.opencontainers.image.source="https://github.com/yesvus/infra-images" \
      org.opencontainers.image.description="Tezgah non-root ARM64 development toolchain"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      bash ca-certificates curl git openssh-client openssh-server \
      python3 python3-venv build-essential pkg-config iproute2 \
      procps tmux tini passwd gh \
 && rm -f /etc/ssh/ssh_host_* \
 && mkdir -p /run/sshd \
 && chmod 0755 /run/sshd \
 && rm -rf /var/lib/apt/lists/* \
 && npm install --global --no-audit --no-fund \
      "@opencode/cli@$OPENCODE_VERSION" "@openai/codex@$CODEX_VERSION" \
      "@anthropic-ai/claude-code@$CLAUDE_CODE_VERSION" \
 && npm cache clean --force

# Version-pinned upstream ARM64 releases with independently retrieved GitHub
# release-asset SHA-256. Both are tools only; never bake credentials into image.
RUN set -eu; \
    test "$(dpkg --print-architecture)" = arm64; \
    curl --fail --location --silent --show-error --retry 3 \
      "https://github.com/google-antigravity/antigravity-cli/releases/download/${AGY_VERSION}/agy_cli_linux_arm64.tar.gz" \
      -o /tmp/agy.tar.gz; \
    echo "${AGY_ARM64_SHA256}  /tmp/agy.tar.gz" | sha256sum -c -; \
    tar -xzf /tmp/agy.tar.gz -C /usr/local/bin/ antigravity; \
    mv /usr/local/bin/antigravity /usr/local/bin/agy; \
    chmod 0755 /usr/local/bin/agy; \
    rm -f /tmp/agy.tar.gz; \
    curl --fail --location --silent --show-error --retry 3 \
      "https://github.com/coder/code-server/releases/download/v${CODE_SERVER_VERSION}/code-server-${CODE_SERVER_VERSION}-linux-arm64.tar.gz" \
      -o /tmp/code-server.tar.gz; \
    echo "${CODE_SERVER_ARM64_SHA256}  /tmp/code-server.tar.gz" | sha256sum -c -; \
    mkdir -p /opt; \
    tar -xzf /tmp/code-server.tar.gz -C /opt; \
    ln -s "/opt/code-server-${CODE_SERVER_VERSION}-linux-arm64/bin/code-server" /usr/local/bin/code-server; \
    rm -f /tmp/code-server.tar.gz

RUN groupadd --gid 10001 dev \
 && useradd --uid 10001 --gid 10001 --shell /bin/bash --home-dir /workspace/.home --no-create-home dev \
 && usermod -p '*' dev \
 && mkdir -p /workspace /workspace/.home \
 && chown -R 10001:10001 /workspace

COPY --chmod=0755 entrypoint.sh /usr/local/bin/dev-entrypoint
COPY --chmod=0644 sshd_config /etc/ssh/sshd_config_tezgah

ENV HOME=/workspace/.home \
    XDG_CONFIG_HOME=/workspace/.home/.config \
    XDG_DATA_HOME=/workspace/.home/.local/share \
    XDG_CACHE_HOME=/workspace/.home/.cache \
    CODEX_HOME=/workspace/.home/.codex \
    CLAUDE_CONFIG_DIR=/workspace/.home/.claude \
    DISABLE_AUTOUPDATER=1 \
    NPM_CONFIG_CACHE=/workspace/.home/.cache/npm \
    LANG=C.UTF-8

WORKDIR /workspace
USER 10001:10001
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/dev-entrypoint"]
CMD ["/usr/sbin/sshd", "-D", "-e", "-f", "/etc/ssh/sshd_config_tezgah"]
