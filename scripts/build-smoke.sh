#!/usr/bin/env bash
set -euo pipefail
if [[ "$#" -ne 1 ]]; then echo "Usage: $0 arc-runner|arc-opencode|tezgah" >&2; exit 2; fi
image="$1"
case "$image" in
  arc-runner) arch=arm64; directory=images/arc-runner ;;
  arc-opencode) arch=amd64; directory=images/arc-opencode ;;
  tezgah) arch=arm64; directory=images/tezgah ;;
  *) echo "Unknown image: $image" >&2; exit 2 ;;
esac
actual="$(uname -m)"
if [[ "$arch" == arm64 && "$actual" != aarch64 ]] || [[ "$arch" == amd64 && "$actual" != x86_64 ]]; then
  echo "Use a native $arch runner; got $actual" >&2
  exit 3
fi
tag="infra-$image:smoke"
docker buildx build --load --platform "linux/$arch" --tag "$tag" \
  --file "$directory/Dockerfile" "$directory"
case "$image" in
  tezgah)
    expected_opencode="$(sed -n 's/^ARG OPENCODE_VERSION=//p' images/tezgah/Dockerfile)"
    expected_agy="$(sed -n 's/^ARG AGY_VERSION=//p' images/tezgah/Dockerfile)"
    test -n "$expected_opencode"; test -n "$expected_agy"
    docker run --rm --network none --platform linux/arm64 --read-only \
      --cap-drop ALL --security-opt no-new-privileges \
      --tmpfs /tmp:rw,nosuid,nodev,size=67108864,uid=10001,gid=10001 \
      --tmpfs /workspace:rw,nosuid,nodev,size=67108864,uid=10001,gid=10001,mode=0700 \
      --env "EXPECTED_OPENCODE_VERSION=$expected_opencode" \
      --env "EXPECTED_AGY_VERSION=$expected_agy" \
      --mount "type=bind,source=$PWD/images/tezgah/smoke.sh,target=/opt/tezgah-smoke.sh,readonly" \
      "$tag" /bin/sh /opt/tezgah-smoke.sh
    ;;
  arc-runner)
    docker run --rm --network none --platform linux/arm64 --read-only \
      --cap-drop ALL --security-opt no-new-privileges --entrypoint /bin/bash \
      "$tag" -ec 'test "$(id -u)" != 0; test "$(uname -m)" = aarch64; gh --version; kubectl version --client; k3s kubectl version --client; test -x /home/runner/run.sh'
    ;;
  arc-opencode)
    docker run --rm --network none --platform linux/amd64 --read-only \
      --cap-drop ALL --security-opt no-new-privileges --entrypoint /bin/bash \
      "$tag" -ec 'test "$(id -u)" = 1001; test "$(uname -m)" = x86_64; test "$(opencode --version)" = "opencode v2.3.0"; test -x /home/runner/run.sh'
    ;;
esac
echo "IMAGE_SMOKE_OK image=$image arch=$arch tag=$tag"
