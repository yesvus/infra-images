# Ephemeral OpenCode agent runner for linux/amd64 ARC runners.
# Existing official ARC runner remains the base; no Tezgah filesystem or auth.
FROM node:24-bookworm-slim@sha256:dc26ae92c9fb15cf6b1d63e20f0944b2efe0f115b20e00be48fb23fceb061c54 AS opencode-builder
ARG OPENCODE_VERSION=2.3.0
RUN npm install --global --no-audit --no-fund "@opencode/cli@${OPENCODE_VERSION}" \
 && test "$(opencode --version)" = "opencode v${OPENCODE_VERSION}"

FROM ghcr.io/actions/actions-runner@sha256:e5496277be5d09bc968b3d64911b74e219ac4a3f2edce956a3ecf9271bea1ef4
USER root
COPY --from=opencode-builder /usr/local/lib/node_modules/@opencode/cli /opt/opencode/cli
RUN ln -s /opt/opencode/cli/bin/opencode.exe /usr/local/bin/opencode \
 && test -x /usr/local/bin/opencode
ENV OPENCODE_DISABLE_AUTOUPDATE=1
USER runner
