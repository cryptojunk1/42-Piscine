#!/bin/bash
# checker.sh – Shell00 ex08: clean
PEER_DIR="$1"
RED='\033[0;31m'; GREEN='\033[0;32m'; BOLD='\033[1m'; RESET='\033[0m'
TP=0; TT=0

echo -e "${BOLD}[1] Datei 'clean' vorhanden?${RESET}"
TT=$((TT+1))
[ -f "$PEER_DIR/clean" ] && { echo -e "${GREEN}✓${RESET}"; TP=$((TP+1)); } || { echo -e "${RED}✗${RESET}"; echo "SCORE:0/3"; exit 1; }

echo -e "${BOLD}[2] Enthält find-Befehl?${RESET}"
TT=$((TT+1))
if grep -q "find" "$PEER_DIR/clean"; then echo -e "${GREEN}✓${RESET}"; TP=$((TP+1)); else echo -e "${RED}✗ kein find${RESET}"; fi

echo -e "${BOLD}[3] Kein Semikolon oder && (ein Befehl)?${RESET}"
TT=$((TT+1))
if ! grep -qE ";|&&|\|\|" "$PEER_DIR/clean"; then echo -e "${GREEN}✓ kein ; oder &&${RESET}"; TP=$((TP+1)); else echo -e "${RED}✗ ; oder && gefunden – nur EIN Befehl erlaubt${RESET}"; fi

echo -e "\n${BOLD}Test: Löscht die Datei tilde-Dateien und #...#-Dateien?${RESET}"
TMPDIR=$(mktemp -d); trap "rm -rf $TMPDIR" EXIT
touch "$TMPDIR/test~" "$TMPDIR/#test#" "$TMPDIR/keep.txt"
mkdir "$TMPDIR/sub"; touch "$TMPDIR/sub/file~"
BEFORE=$(find "$TMPDIR" -name "*~" -o -name "#*#" | wc -l)
( cd "$TMPDIR" && eval "$(cat "$PEER_DIR/clean")" 2>/dev/null )
AFTER=$(find "$TMPDIR" -name "*~" -o -name "#*#" | wc -l)
TT=$((TT+1))
if [ "$AFTER" -eq 0 ] && [ "$BEFORE" -gt 0 ]; then echo -e "${GREEN}✓ Dateien gelöscht${RESET}"; TP=$((TP+1)); else echo -e "${RED}✗ Dateien nicht gelöscht (vorher: $BEFORE, nachher: $AFTER)${RESET}"; fi

echo "SCORE:$TP/$TT"
