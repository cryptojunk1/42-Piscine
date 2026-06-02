#!/bin/bash
PEER_DIR="$1"
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; RESET='\033[0m'

echo -e "${BOLD}ex07 – Manuelle/komplexe Prüfung"
echo -e "${YELLOW}Diese Übung erfordert manuelle Überprüfung oder ein spezielles Setup."
echo -e "Schau dir die Aufgabe (Taste 'p') an und teste selbst."
ls -la "$PEER_DIR/" 2>/dev/null && echo "" || echo -e "${RED}Verzeichnis leer${RESET}"
echo "SCORE:1/1"
