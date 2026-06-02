#!/bin/bash
# checker.sh – Shell00 ex02: exo2.tar (manuelle Prüfung)
PEER_DIR="$1"
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; RESET='\033[0m'
TP=0; TT=1

echo -e "${BOLD}[1] Datei 'exo2.tar' vorhanden?"
if [ -f "$PEER_DIR/exo2.tar" ]; then
  echo -e "${GREEN}✓ Datei gefunden${RESET}"
  echo -e "${YELLOW}⚠ Diese Übung erfordert manuelle Prüfung."
  echo -e "  Lies das Subject (Taste 'p') für Details."
  TP=1
else
  echo -e "${RED}✗ $PEER_DIR/exo2.tar nicht gefunden${RESET}"
fi

echo "SCORE:$TP/$TT"
