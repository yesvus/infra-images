#!/bin/sh
set -eu
# Root filesystem can be read-only; home and all agent state are on the PVC.
if [ ! -d /workspace ] || [ ! -w /workspace ]; then
  echo "ERROR: /workspace must be a writable, user-owned persistent mount" >&2
  exit 20
fi
umask 077
mkdir -p "$HOME" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_HOME" "$CODEX_HOME" "$CLAUDE_CONFIG_DIR" "$HOME/.ssh"
chmod 0700 "$HOME" "$HOME/.ssh" "$CODEX_HOME" "$CLAUDE_CONFIG_DIR"
# In SSH server mode, refuse to listen until an explicitly provisioned,
# valid Mac public key exists. Private host key is generated on the PVC,
# never in the image. The key survives Pod recreation; verify/pin its
# fingerprint from a trusted kubectl session on first setup.
if [ "$1" = /usr/sbin/sshd ]; then
  if [ ! -s "$HOME/.ssh/authorized_keys" ]; then
    echo "ERROR: owner public key not provisioned at $HOME/.ssh/authorized_keys" >&2
    exit 21
  fi
  chmod 0600 "$HOME/.ssh/authorized_keys"
  ssh-keygen -l -f "$HOME/.ssh/authorized_keys" >/dev/null || {
    echo "ERROR: authorized_keys does not contain a valid SSH public key" >&2
    exit 22
  }
  if [ ! -f "$HOME/.ssh/ssh_host_ed25519_key" ]; then
    ssh-keygen -q -t ed25519 -N '' -f "$HOME/.ssh/ssh_host_ed25519_key"
  fi
  chmod 0600 "$HOME/.ssh/ssh_host_ed25519_key"
  /usr/sbin/sshd -t -f /etc/ssh/sshd_config_tezgah
fi
exec "$@"
