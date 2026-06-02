#!/bin/bash
# checker.sh – Shell00 ex03: id_rsa_pub (manuelle Prüfung)
PEER_DIR="$1"
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; RESET='\033[0m'
TP=0; TT=1

echo -e "${BOLD}[1] Datei 'id_rsa_pub' vorhanden?"
if [ -f "$PEER_DIR/id_rsa_pub" ]; then
  echo -e "${GREEN}✓ Datei gefunden${RESET}"
  echo -e "${YELLOW}⚠ Diese Übung erfordert manuelle Prüfung."
  echo -e "  Lies das Subject (Taste 'p') für Details."
  TP=1
else
  echo -e "${RED}✗ $PEER_DIR/id_rsa_pub nicht gefunden${RESET}"
fi

echo "SCORE:$TP/$TT"
