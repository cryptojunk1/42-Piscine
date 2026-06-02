#!/bin/bash
PEER_DIR="$1"
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; RESET='\033[0m'
TP=0; TT=0

echo -e "${BOLD}[1] MAC.sh vorhanden?${RESET}"; TT=$((TT+1))
[ -f "$PEER_DIR/MAC.sh" ] && { echo -e "${GREEN}✓${RESET}"; TP=$((TP+1)); } || { echo -e "${RED}✗${RESET}"; echo "SCORE:0/2"; exit 1; }

echo -e "${BOLD}[2] Gibt MAC-Adresse(n) aus?${RESET}"; TT=$((TT+1))
OUT=$(bash "$PEER_DIR/MAC.sh" 2>/dev/null)
if echo "$OUT" | grep -qE "([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}"; then
  echo -e "${GREEN}✓ MAC gefunden: $OUT${RESET}"; TP=$((TP+1))
else
  echo -e "${YELLOW}⚠ Kein MAC im Output: '$OUT'${RESET} (auf manchen WSL-Setups leer)"
fi

echo "SCORE:$TP/$TT"
