#!/bin/bash
# =============================================================================
# 42 Lerntool – migrate_repo.sh  (EINMALIG in WSL ausführen)
# Verschiebt das Git-Repo vom OneDrive-Root (mit 2,7 GB PDFs) in den
# Tool-Ordner 42-lerntool/. Deine Dateien bleiben unangetastet – es wird
# nur die .git-Verwaltung umgezogen.
#
# Aufruf:  bash scripts/migrate_repo.sh
# Danach pushst du selbst (Git lernt man durch Tun) – der Befehl wird angezeigt.
# =============================================================================

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOL_ROOT="$(dirname "$SCRIPT_DIR")"
OLD_ROOT="$(dirname "$TOOL_ROOT")"   # OneDrive/42

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

echo -e "${BOLD}Repo-Migration: OneDrive-Root → 42-lerntool/${RESET}\n"

# Remote-URL aus dem alten Repo retten (falls vorhanden)
REMOTE=""
if [ -d "$OLD_ROOT/.git" ]; then
  REMOTE="$(git -C "$OLD_ROOT" remote get-url origin 2>/dev/null || true)"
fi
[ -z "$REMOTE" ] && REMOTE="git@github.com:cryptojunk1/42-Piscine.git"
echo -e "Remote: ${CYAN}$REMOTE${RESET}"

# Falls im Tool-Ordner schon ein Repo liegt: abbrechen (nichts kaputtmachen)
if [ -d "$TOOL_ROOT/.git" ]; then
  echo -e "${YELLOW}Im Tool-Ordner existiert bereits ein .git – Migration übersprungen.${RESET}"
  echo -e "Falls du neu aufsetzen willst, lösche zuerst: ${CYAN}rm -rf \"$TOOL_ROOT/.git\"${RESET}"
  exit 0
fi

# 1. Altes Root-Repo entfernen (NUR die .git-Verwaltung, KEINE Dateien!)
if [ -d "$OLD_ROOT/.git" ]; then
  echo -e "\n${BOLD}1)${RESET} Entferne alte .git-Verwaltung am OneDrive-Root (Dateien bleiben erhalten) ..."
  rm -rf "$OLD_ROOT/.git"
  echo -e "${GREEN}✓ erledigt${RESET}"
fi

# 2. Neues Repo im Tool-Ordner
echo -e "\n${BOLD}2)${RESET} Initialisiere neues Repo in 42-lerntool/ ..."
cd "$TOOL_ROOT"
git init -b main >/dev/null
git add .
git -c user.name="${GIT_AUTHOR_NAME:-Rene}" -c user.email="${GIT_AUTHOR_EMAIL:-renemessner87@gmail.com}" \
    commit -m "C00: Lerntool als eigenständiges Repo (Launcher, Scripts, Lösungen)" >/dev/null
echo -e "${GREEN}✓ erstes Commit erstellt${RESET}"

# 3. Remote setzen
git remote add origin "$REMOTE" 2>/dev/null || git remote set-url origin "$REMOTE"
echo -e "${GREEN}✓ Remote verbunden${RESET}"

echo -e "\n${BOLD}Fast fertig!${RESET} Jetzt pushst du selbst:"
echo -e "  ${CYAN}cd \"$TOOL_ROOT\"${RESET}"
echo -e "  ${CYAN}git push -u origin main --force${RESET}   ${YELLOW}# --force überschreibt das alte init-Commit auf GitHub${RESET}"
echo ""
echo -e "${BOLD}Was sich ändert:${RESET}"
echo -e "  • Git scannt nur noch den Tool-Ordner (schnell), nicht mehr 2,7 GB PDFs."
echo -e "  • Deine Lösungen (peer/*.c) und Scripts landen sauber auf GitHub."
echo -e "  • Die 42-Subjects bleiben lokal/privat (Urheberrecht)."
echo -e "  • progress.json bleibt im OneDrive-Root und synct weiter via OneDrive."
