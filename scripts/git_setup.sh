#!/bin/bash
# =============================================================================
# 42 Lerntool -- git_setup.sh
# Richtet das GitHub-Repository ein (einmalig) und erstellt .gitignore
# Usage: bash scripts/git_setup.sh
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOL_ROOT="$(dirname "$SCRIPT_DIR")"
REPO_ROOT="$(dirname "$TOOL_ROOT")"

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'
BOLD='\033[1m'; RED='\033[0;31m'; RESET='\033[0m'

echo -e "\n${BOLD}=== 42 Lerntool - GitHub Setup ===${RESET}\n"

# --- Git installiert? ---
if ! command -v git &>/dev/null; then
  echo -e "${RED}git nicht gefunden. Installiere: sudo apt install git${RESET}"
  exit 1
fi

# --- Schon initialisiert? ---
if git -C "$REPO_ROOT" rev-parse --git-dir &>/dev/null 2>&1; then
  echo -e "${YELLOW}Git-Repo existiert bereits unter: $REPO_ROOT${RESET}"
  REMOTE=$(git -C "$REPO_ROOT" remote get-url origin 2>/dev/null || echo "")
  if [ -n "$REMOTE" ]; then
    echo -e "Remote: ${CYAN}$REMOTE${RESET}"
    echo -e "\nAktueller Status:"
    git -C "$REPO_ROOT" log --oneline -5 2>/dev/null || echo "(noch keine commits)"
    echo ""
    echo -e "Fortfahren? ${CYAN}bash scripts/git_commit.sh${RESET}"
    exit 0
  fi
fi

# --- Git-Konfiguration prüfen ---
GIT_NAME=$(git config --global user.name 2>/dev/null || echo "")
GIT_EMAIL=$(git config --global user.email 2>/dev/null || echo "")

if [ -z "$GIT_NAME" ]; then
  echo -ne "Dein Name für Git-Commits: "
  read -r GIT_NAME
  git config --global user.name "$GIT_NAME"
fi
if [ -z "$GIT_EMAIL" ]; then
  echo -ne "Deine GitHub-Email: "
  read -r GIT_EMAIL
  git config --global user.email "$GIT_EMAIL"
fi

echo -e "\nGit-Benutzer: ${CYAN}$GIT_NAME <$GIT_EMAIL>${RESET}"

# --- GitHub Repo URL ---
echo ""
echo -e "${BOLD}GitHub-Repo erstellen:${RESET}"
echo -e "  1. Gehe zu ${CYAN}https://github.com/new${RESET}"
echo -e "  2. Repository name: ${CYAN}42-Piscine${RESET}"
echo -e "  3. Visibility: ${CYAN}Public${RESET}"
echo -e "  4. KEIN README, KEIN .gitignore (wird hier erstellt)"
echo -e "  5. Create repository → SSH-URL kopieren"
echo ""
echo -ne "GitHub Repository URL (z.B. git@github.com:deinname/42-piscine.git): "
read -r REPO_URL

if [ -z "$REPO_URL" ]; then
  echo -e "${RED}Keine URL eingegeben. Abgebrochen.${RESET}"
  exit 1
fi

# --- .gitignore erstellen ---
cat > "$REPO_ROOT/.gitignore" << 'GITIGNEOF'
# Dashboard (wird generiert)
42-lerntool/dashboard.html

# Exam-Sessions (temporaer)
42-lerntool/exam/session_*/

# Python cache
__pycache__/
*.pyc

# macOS
.DS_Store

# Windows
Thumbs.db
Desktop.ini

# Editor
.vscode/
.idea/
*.swp
GITIGNEOF

# --- README erstellen ---
cat > "$REPO_ROOT/README.md" << 'READMEEOF'
# 42 Piscine – Self-Study

Solo-Lernprojekt: das 42 Network Piscine-Programm im Selbststudium nachholen.

## Struktur

```
42-lerntool/
├── subjects/       # Aufgaben-Specs (JSON mit deutschen Beschreibungen + Hints)
├── peer/           # Arbeitsordner: .c-Dateien je Uebung + CLAUDE.md (Tutor-Regeln)
├── exam/           # Mini-Exam im 42-Stil (eskalierend, Timer, Auto-Bewertung)
├── rewards/        # Trophaeenschrank-Daten
└── scripts/        # check.sh, update_progress.sh, trophy.sh, generate_dashboard.py
progress.json       # Fortschritts-Status (XP, Level, Badges, Exam-Scores)
```

## Tools

| Befehl | Funktion |
|--------|---------|
| `bash scripts/new.sh <uebung>` | Neue Uebung anlegen |
| `bash scripts/check.sh <uebung>` | Norminette + Tests |
| `bash scripts/update_progress.sh <uebung> <score>` | XP eintragen |
| `bash exam/exam.sh` | Mini-Exam (60 Min) |
| `python3 scripts/generate_dashboard.py --open` | Dashboard oeffnen |

## Fortschritt

<!-- Wird automatisch durch update_progress.sh aktualisiert -->
READMEEOF

# --- Git init + first commit ---
cd "$REPO_ROOT"
git init -b main 2>/dev/null || git init && git checkout -b main 2>/dev/null
git remote add origin "$REPO_URL" 2>/dev/null || git remote set-url origin "$REPO_URL"

git add .gitignore README.md
git add 42-lerntool/subjects/
git add 42-lerntool/peer/CLAUDE.md
git add 42-lerntool/scripts/
git add 42-lerntool/exam/
git add progress.json 2>/dev/null || true

git commit -m "init: 42 Piscine Lerntool Setup (C00)"

echo ""
echo -e "${GREEN}${BOLD}Git-Repo initialisiert!${RESET}"
echo -e "Remote: ${CYAN}$REPO_URL${RESET}"
echo ""
echo -e "${BOLD}Jetzt pushen:${RESET}"
echo -e "  ${CYAN}git -C '$REPO_ROOT' push -u origin main${RESET}"
echo ""
echo -e "${YELLOW}Tipp: SSH-Key einrichten falls nicht vorhanden:${RESET}"
echo -e "  ${CYAN}ssh-keygen -t ed25519 -C '$GIT_EMAIL'${RESET}"
echo -e "  ${CYAN}cat ~/.ssh/id_ed25519.pub${RESET}  → zu GitHub Settings > SSH Keys hinzufügen"
echo ""

# Erstelle git_commit.sh für spätere Commits
cat > "$SCRIPT_DIR/git_commit.sh" << 'COMMITEOF'
#!/bin/bash
# Schnell-Commit nach bestandener Uebung
# Usage: bash scripts/git_commit.sh [message]
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
MSG="${1:-C00: Fortschritt}"
cd "$REPO_ROOT"
git add -A
git status --short
git commit -m "$MSG" && git push origin main && echo "Gepusht!"
COMMITEOF
chmod +x "$SCRIPT_DIR/git_commit.sh"
echo -e "Schnell-Commit nach Uebungen: ${CYAN}bash scripts/git_commit.sh 'C00: ft_putchar 100/100'${RESET}"
