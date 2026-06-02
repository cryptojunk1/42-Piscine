#!/bin/bash
PEER_DIR="$1"
RED='\033[0;31m'; GREEN='\033[0;32m'; BOLD='\033[1m'; RESET='\033[0m'
TP=0; TT=0

echo -e "${BOLD}[1] print_groups.sh vorhanden?${RESET}"; TT=$((TT+1))
[ -f "$PEER_DIR/print_groups.sh" ] && { echo -e "${GREEN}✓${RESET}"; TP=$((TP+1)); } || { echo -e "${RED}✗${RESET}"; echo "SCORE:0/3"; exit 1; }

echo -e "${BOLD}[2] Shebang vorhanden?${RESET}"; TT=$((TT+1))
head -1 "$PEER_DIR/print_groups.sh" | grep -q "^#!" && { echo -e "${GREEN}✓${RESET}"; TP=$((TP+1)); } || echo -e "${RED}✗${RESET}"

echo -e "${BOLD}[3] Enthält id-Befehl?${RESET}"; TT=$((TT+1))
grep -q "id " "$PEER_DIR/print_groups.sh" && { echo -e "${GREEN}✓${RESET}"; TP=$((TP+1)); } || echo -e "${RED}✗ kein id-Befehl${RESET}"

echo -e "\n${BOLD}Test mit FT_USER=root:${RESET}"
OUT=$(FT_USER=root bash "$PEER_DIR/print_groups.sh" 2>/dev/null)
echo "  Output: $OUT"
[ -n "$OUT" ] && echo -e "${GREEN}✓ gibt Gruppen aus${RESET}" || echo -e "${RED}✗ kein Output${RESET}"

echo "SCORE:$TP/$TT"
