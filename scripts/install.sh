#!/bin/bash
# =============================================================================
# 42 Lerntool – install.sh  (einmalig in WSL ausführen)
# Richtet den Kurzbefehl `42` ein, sodass du das Lerntool von überall startest.
# Aufruf:  bash scripts/install.sh
# =============================================================================

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOL_ROOT="$(dirname "$SCRIPT_DIR")"
GO="$TOOL_ROOT/go.sh"

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; RESET='\033[0m'

chmod +x "$GO" "$SCRIPT_DIR"/*.sh "$TOOL_ROOT/exam/exam.sh" 2>/dev/null

BASHRC="$HOME/.bashrc"
ALIAS_LINE="alias 42='bash \"$GO\"'"
MARK="# >>> 42-lerntool >>>"

if grep -qF "$MARK" "$BASHRC" 2>/dev/null; then
  # bestehenden Block ersetzen (Pfad könnte sich geändert haben)
  sed -i "/# >>> 42-lerntool >>>/,/# <<< 42-lerntool <<</d" "$BASHRC"
fi
{
  echo "$MARK"
  echo "$ALIAS_LINE"
  echo "# <<< 42-lerntool <<<"
} >> "$BASHRC"

echo -e "\n${GREEN}${BOLD}✓ Fertig eingerichtet!${RESET}"
echo -e "Der Befehl ${CYAN}${BOLD}42${RESET} startet jetzt dein Lerntool."
echo ""
echo -e "${YELLOW}Einmal noch aktivieren (oder neues Terminal öffnen):${RESET}"
echo -e "  ${CYAN}source ~/.bashrc${RESET}"
echo ""
echo -e "Dann einfach tippen:  ${CYAN}${BOLD}42${RESET}"
