#!/bin/bash
# checker.sh – Shell00 ex01: testShell00.tar
PEER_DIR="$1"
RED='\033[0;31m'; GREEN='\033[0;32m'; BOLD='\033[1m'; RESET='\033[0m'
TP=0; TT=0

echo -e "${BOLD}[1] testShell00.tar vorhanden?${RESET}"
TT=$((TT+1))
if [ -f "$PEER_DIR/testShell00.tar" ]; then echo -e "${GREEN}✓${RESET}"; TP=$((TP+1)); else echo -e "${RED}✗${RESET}"; echo "SCORE:$TP/$TT"; exit 1; fi

TMPDIR=$(mktemp -d); trap "rm -rf $TMPDIR" EXIT
tar -xf "$PEER_DIR/testShell00.tar" -C "$TMPDIR" 2>/dev/null

echo -e "${BOLD}[2] testShell00 enthalten?${RESET}"
TT=$((TT+1))
if [ -f "$TMPDIR/testShell00" ]; then echo -e "${GREEN}✓${RESET}"; TP=$((TP+1)); else echo -e "${RED}✗ Datei nicht im Archiv${RESET}"; echo "SCORE:$TP/$TT"; exit 1; fi

echo -e "${BOLD}[3] Berechtigungen -r--r-xr-x (455)?${RESET}"
TT=$((TT+1))
PERMS=$(stat -c "%a" "$TMPDIR/testShell00" 2>/dev/null)
if [ "$PERMS" = "455" ]; then echo -e "${GREEN}✓ $PERMS${RESET}"; TP=$((TP+1)); else echo -e "${RED}✗ Erwartet: 455, bekommen: $PERMS${RESET}"; fi

echo "SCORE:$TP/$TT"
