#!/usr/bin/env bash
# Installs the Kanki TDM server on an Ubuntu VPS and starts it as a service
# (it also starts again by itself after a reboot or a crash).
#
# 1. Download "KankiTDM-server" from GitHub Actions and unzip it.
# 2. Upload the folder to the VPS (e.g. with WinSCP or scp).
# 3. In that folder run:   sudo bash install-server.sh
#
# Other port:   sudo PORT=8000 bash install-server.sh
set -euo pipefail

PORT="${PORT:-7777}"
DIR=/opt/kanki-tdm
cd "$(dirname "$0")"

if [ ! -f KankiTDM-server.x86_64 ]; then
  echo "KankiTDM-server.x86_64 not found next to this script." >&2
  exit 1
fi

mkdir -p "$DIR"
systemctl stop kanki-tdm 2>/dev/null || true
cp KankiTDM-server.x86_64 "$DIR/"
chmod +x "$DIR/KankiTDM-server.x86_64"

if ! id -u kanki >/dev/null 2>&1; then
  useradd --system --home "$DIR" --shell /usr/sbin/nologin kanki
fi
chown -R kanki:kanki "$DIR"

sed "s/--port=7777/--port=$PORT/" kanki-tdm.service > /etc/systemd/system/kanki-tdm.service
systemctl daemon-reload
systemctl enable kanki-tdm
systemctl restart kanki-tdm

if command -v ufw >/dev/null 2>&1; then
  ufw allow "$PORT/udp" || true
  ufw allow "$((PORT + 1))/udp" || true   # accounts (sign up / log in)
fi

sleep 2
systemctl --no-pager status kanki-tdm | head -n 12
echo
echo "Done. Players join with this server's IP (UDP port $PORT)."
echo "Live log:   journalctl -u kanki-tdm -f"
