#!/usr/bin/env bash
# Installs the locally hosted Atlantis for shopnest-ado on this machine, as
# systemd user services, from the files in this directory. Safe to re-run:
# it never overwrites an existing secrets.env and skips binaries already at
# the pinned version. Run as the user Atlantis should act as — it uses that
# user's `az login` for Azure.
set -euo pipefail

ATLANTIS_VERSION=0.48.0
NGROK_DOMAIN=quarrel-skydiver-outsource.ngrok-free.dev

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bin="$HOME/.local/bin"
conf="$HOME/.config/atlantis"
units="$HOME/.config/systemd/user"

die() { echo "error: $*" >&2; exit 1; }

# Plans shell out to all of these; they need root to install, so check
# rather than install them.
for tool in az terraform terragrunt kubelogin git curl unzip sha256sum; do
  command -v "$tool" >/dev/null || die "'$tool' is not installed or not on PATH"
done
az account show >/dev/null 2>&1 || die "not logged in to Azure — run 'az login' first"

mkdir -p "$bin" "$conf" "$units"

if [ "$("$bin/atlantis" version 2>/dev/null | awk '{print $2}')" != "$ATLANTIS_VERSION" ]; then
  echo "installing atlantis $ATLANTIS_VERSION"
  tmp="$(mktemp -d)"
  trap 'rm -rf -- "${tmp:?}"' EXIT
  base="https://github.com/runatlantis/atlantis/releases/download/v$ATLANTIS_VERSION"
  curl -sSfL -o "$tmp/atlantis_linux_amd64.zip" "$base/atlantis_linux_amd64.zip"
  curl -sSfL -o "$tmp/checksums.txt" "$base/checksums.txt"
  (cd "$tmp" && grep " atlantis_linux_amd64.zip$" checksums.txt | sha256sum -c -)
  unzip -o -q "$tmp/atlantis_linux_amd64.zip" atlantis -d "$bin"
fi

if ! command -v ngrok >/dev/null; then
  echo "installing ngrok"
  curl -sSfL https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz | tar -xz -C "$bin" ngrok
fi
ngrok config check >/dev/null 2>&1 && grep -q authtoken "$HOME/.config/ngrok/ngrok.yml" 2>/dev/null \
  || die "ngrok has no authtoken — run 'ngrok config add-authtoken <token>' (see README.md)"

install -m 644 "$here/config.yaml" "$here/repos.yaml" "$conf/"
if [ ! -f "$conf/secrets.env" ]; then
  install -m 600 "$here/secrets.env.example" "$conf/secrets.env"
  die "created $conf/secrets.env from the example — fill it in, then re-run this script"
fi
chmod 600 "$conf/secrets.env"
grep -qE '^ATLANTIS_[A-Z_]+=$' "$conf/secrets.env" && die "$conf/secrets.env still has empty values"

install -m 644 "$here/atlantis.service" "$here/ngrok-atlantis.service" "$units/"
systemctl --user daemon-reload
systemctl --user enable atlantis.service ngrok-atlantis.service
systemctl --user restart atlantis.service ngrok-atlantis.service

if [ "$(loginctl show-user "$USER" -p Linger --value 2>/dev/null)" != "yes" ]; then
  echo "note: services stop when you log out until you run: sudo loginctl enable-linger $USER"
fi

sleep 5
code="$(curl -s -o /dev/null -w '%{http_code}' "https://$NGROK_DOMAIN/healthz" || true)"
[ "$code" = 200 ] || die "https://$NGROK_DOMAIN/healthz returned $code — check: journalctl --user -u atlantis -u ngrok-atlantis"
echo "atlantis is up at https://$NGROK_DOMAIN"
