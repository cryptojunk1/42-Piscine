#!/bin/bash
# checker.sh – Shell00 ex06: git_ignore.sh
PEER_DIR="$1"
RED='\033[0;31m'; GREEN='\033[0;32m'; BOLD='\033[1m'; RESET='\033[0m'
TP=0; TT=0

echo -e "${BOLD}[1] git_ignore.sh vorhanden?${RESET}"
TT=$((TT+1))
[ -f "$PEER_DIR/git_ignore.sh" ] && { echo -e "${GREEN}✓${RESET}"; TP=$((TP+1)); } || { echo -e "${RED}✗${RESET}"; echo "SCORE:0/3"; exit 1; }

echo -e "${BOLD}[2] Shebang vorhanden?${RESET}"
TT=$((TT+1))
head -1 "$PEER_DIR/git_ignore.sh" | grep -q "^#!" && { echo -e "${GREEN}✓${RESET}"; TP=$((TP+1)); } || echo -e "${RED}✗${RESET}"

echo -e "${BOLD}[3] Enthält git ls-files oder git check-ignore?${RESET}"
TT=$((TT+1))
if grep -qE "git (ls-files|check-ignore)" "$PEER_DIR/git_ignore.sh"; then echo -e "${GREEN}✓${RESET}"; TP=$((TP+1)); else echo -e "${RED}✗ git ls-files/check-ignore fehlt${RESET}"; fi

echo "SCORE:$TP/$TT"
