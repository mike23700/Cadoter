#!/usr/bin/env bash
# Lance l'app sur un téléphone branché en USB, avec l'API du PC (backend Docker sur le port 8001).
# La redirection « adb reverse » saute à chaque débranchement du câble ou redémarrage d'adb :
# ce script la rétablit systématiquement avant flutter run.
#   ./run.sh                 → premier appareil connecté
#   ./run.sh <id-appareil>   → appareil précis (voir « adb devices »)
#   ./run.sh <id> --release  → arguments supplémentaires transmis à flutter run
set -euo pipefail
cd "$(dirname "$0")"

DEVICE="${1:-$(adb devices | awk 'NR>1 && $2=="device" {print $1; exit}')}"
[ -z "$DEVICE" ] && { echo "Aucun appareil Android détecté (adb devices)." >&2; exit 1; }
shift || true

curl -sf -o /dev/null http://localhost:8001/api/meta \
  || echo "⚠ L'API ne répond pas sur localhost:8001 — lancer : cd ../../backend && docker compose up -d" >&2

adb -s "$DEVICE" reverse tcp:8001 tcp:8001
echo "✓ Redirection USB active : localhost:8001 (téléphone) → localhost:8001 (PC)"

exec flutter run -d "$DEVICE" --dart-define=API_URL=http://localhost:8001/api "$@"
