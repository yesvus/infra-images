#!/bin/sh
set -eu
test "$(id -u)" = 10001
test "$(uname -m)" = aarch64
test "$HOME" = /workspace/.home
touch "$HOME/.smoke"
test -f "$HOME/.smoke"
command -v ss
ss -tlnp >/dev/null
node --version
python3 --version
git --version
timeout 20 opencode --version
timeout 20 codex --version
timeout 20 claude --version
timeout 20 agy --version
timeout 20 gh --version
timeout 20 code-server --version
test "$(opencode --version)" = "opencode v$EXPECTED_OPENCODE_VERSION"
test "$(agy --version)" = "$EXPECTED_AGY_VERSION"
ssh-keygen -q -t ed25519 -N "" -f "$HOME/.ssh/smoke_client_key"
cp "$HOME/.ssh/smoke_client_key.pub" "$HOME/.ssh/authorized_keys"
chmod 0600 "$HOME/.ssh/authorized_keys"
/usr/local/bin/dev-entrypoint /usr/sbin/sshd -D -e -f /etc/ssh/sshd_config_tezgah >/tmp/sshd-smoke.log 2>&1 &
sshd_pid=$!
trap 'kill "$sshd_pid" 2>/dev/null || true' EXIT
success=0
for i in 1 2 3 4 5 6 7 8 9 10; do
  if timeout 8 ssh -F /dev/null -o BatchMode=yes \
      -o IdentitiesOnly=yes -o PreferredAuthentications=publickey \
      -o StrictHostKeyChecking=accept-new \
      -o UserKnownHostsFile=/tmp/known_hosts \
      -o ConnectTimeout=4 -p 2222 \
      -i "$HOME/.ssh/smoke_client_key" dev@127.0.0.1 \
      id -u >/tmp/ssh-id 2>/tmp/ssh-client.log; then
    success=1; break
  fi
  sleep 1
done
if [ "$success" -ne 1 ]; then cat /tmp/sshd-smoke.log /tmp/ssh-client.log; exit 1; fi
test "$(cat /tmp/ssh-id)" = 10001
echo TEZGAH_SSH_LOOPBACK_LOGIN_OK
