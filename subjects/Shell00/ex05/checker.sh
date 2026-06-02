#!/bin/bash
# checker.sh – Shell00 ex05: git_commit.sh
PEER_DIR="$1"
RED='\033[0;31m'; GREEN='\033[0;32m'; BOLD='\033[1m'; RESET='\033[0m'
TP=0; TT=0

echo -e "${BOLD}[1] git_commit.sh vorhanden?${RESET}"
TT=$((TT+1))
[ -f "$PEER_DIR/git_commit.sh" ] && { echo -e "${GREEN}✓${RESET}"; TP=$((TP+1)); } || { echo -e "${RED}✗${RESET}"; echo "SCORE:0/3"; exit 1; }

echo -e "${BOLD}[2] Shebang #!/bin/sh oder #!/bin/bash?${RESET}"
TT=$((TT+1))
if head -1 "$PEER_DIR/git_commit.sh" | grep -q "^#!"; then echo -e "${GREEN}✓${RESET}"; TP=$((TP+1)); else echo -e "${RED}✗ Kein Shebang${RESET}"; fi

echo -e "${BOLD}[3] Enthält git log Befehl?${RESET}"
TT=$((TT+1))
if grep -q "git log" "$PEER_DIR/git_commit.sh"; then echo -e "${GREEN}✓${RESET}"; TP=$((TP+1)); else echo -e "${RED}✗ Kein git log${RESET}"; fi

echo -e "\n${BOLD}Hinweis:${RESET} Manuell testen mit: bash git_commit.sh (im Repo)"
echo "SCORE:$TP/$TT"
