#!/bin/bash
# =============================================================================
# 42 Lerntool – exam.sh
# Mini-Exam im 42-Stil: eskalierend, Timer, Auto-Bewertung, kein Tutor
# Usage: bash exam.sh [--time <minuten>] [--module C00]
# Default: 60 Minuten, Modul C00
# =============================================================================

# ─── Konfiguration ───────────────────────────────────────────────────────────
EXAM_TIME_MIN=60
MODULE="C00"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --time) EXAM_TIME_MIN="$2"; shift 2 ;;
    --module) MODULE="$2"; shift 2 ;;
    *) shift ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOL_ROOT="$(dirname "$SCRIPT_DIR")"
PROGRESS="$(dirname "$TOOL_ROOT")/progress.json"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BLUE='\033[0;34m'; MAGENTA='\033[0;35m'
BOLD='\033[1m'; DIM='\033[2m'; RESET='\033[0m'

export PATH="$PATH:$HOME/.local/bin"

# ─── Exam-Aufgaben (eskalierend) ─────────────────────────────────────────────
# Level 0: Einstieg (25 Punkte wenn bestanden)
# Level 1: Einfach (50 Punkte wenn hier bestanden)
# Level 2: Mittel (75 Punkte wenn hier bestanden)
# Level 3: Schwer (90 Punkte wenn hier bestanden)
# Level 4: Experte (100 Punkte wenn hier bestanden)

declare -A LEVEL_TASKS=(
  [0]="ft_putchar"
  [1]="ft_print_numbers"
  [2]="ft_is_negative"
  [3]="ft_putnbr"
  [4]="ft_print_combn"
)
declare -A LEVEL_SCORE=(
  [0]=25 [1]=50 [2]=75 [3]=90 [4]=100
)
MAX_LEVEL=4

# ─── Hilfsfunktionen ─────────────────────────────────────────────────────────

show_header() {
  clear
  echo -e "${BOLD}${BLUE}"
  echo "  ╔══════════════════════════════════════════════════╗"
  echo "  ║           42 PISCINE EXAM – $MODULE              ║"
  echo "  ║          *** KEIN TUTOR-ZUGRIFF ***              ║"
  echo "  ╚══════════════════════════════════════════════════╝${RESET}"
}

show_timer() {
  local elapsed=$1
  local total=$((EXAM_TIME_MIN * 60))
  local remaining=$((total - elapsed))
  local mins=$((remaining / 60))
  local secs=$((remaining % 60))
  if [ $remaining -le 300 ]; then
    echo -e "${RED}${BOLD}⏱  VERBLEIBEND: ${mins}m ${secs}s${RESET}"
  elif [ $remaining -le 600 ]; then
    echo -e "${YELLOW}${BOLD}⏱  Verbleibend: ${mins}m ${secs}s${RESET}"
  else
    echo -e "${CYAN}⏱  Verbleibend: ${mins}m ${secs}s${RESET}"
  fi
}

show_task() {
  local level=$1
  local task="${LEVEL_TASKS[$level]}"
  local pts="${LEVEL_SCORE[$level]}"

  echo -e "\n${BOLD}${MAGENTA}════ LEVEL $level – $task (→ $pts Punkte) ════${RESET}"
  echo ""

  case "$task" in
    ft_putchar)
      echo -e "${BOLD}Aufgabe:${RESET} Schreibe die Funktion ${CYAN}ft_putchar${RESET}"
      echo ""
      echo "  void ft_putchar(char c);"
      echo ""
      echo "  Zeigt das Zeichen c auf dem Standard-Output an."
      echo "  Erlaubte Funktionen: write"
      echo "  Datei: ft_putchar.c"
      ;;
    ft_print_numbers)
      echo -e "${BOLD}Aufgabe:${RESET} Schreibe die Funktion ${CYAN}ft_print_numbers${RESET}"
      echo ""
      echo "  void ft_print_numbers(void);"
      echo ""
      echo "  Gibt alle Ziffern auf einer Zeile aus, aufsteigend."
      echo "  Erlaubte Funktionen: write"
      echo "  Datei: ft_print_numbers.c"
      ;;
    ft_is_negative)
      echo -e "${BOLD}Aufgabe:${RESET} Schreibe die Funktion ${CYAN}ft_is_negative${RESET}"
      echo ""
      echo "  void ft_is_negative(int n);"
      echo ""
      echo "  Gibt 'N' aus wenn n negativ, 'P' wenn positiv oder 0."
      echo "  Erlaubte Funktionen: write"
      echo "  Datei: ft_is_negative.c"
      ;;
    ft_putnbr)
      echo -e "${BOLD}Aufgabe:${RESET} Schreibe die Funktion ${CYAN}ft_putnbr${RESET}"
      echo ""
      echo "  void ft_putnbr(int nb);"
      echo ""
      echo "  Gibt den Integer nb auf Standard-Output aus."
      echo "  Muss alle int-Werte inklusive INT_MIN und INT_MAX verarbeiten."
      echo "  Erlaubte Funktionen: write"
      echo "  Datei: ft_putnbr.c"
      ;;
    ft_print_combn)
      echo -e "${BOLD}Aufgabe:${RESET} Schreibe die Funktion ${CYAN}ft_print_combn${RESET}"
      echo ""
      echo "  void ft_print_combn(int n);"
      echo ""
      echo "  Gibt alle verschiedenen Kombinationen von n verschiedenen Ziffern"
      echo "  in aufsteigender Reihenfolge aus. 0 < n < 10."
      echo "  Beispiel n=2: 01, 02, 03, ..., 89"
      echo "  Erlaubte Funktionen: write"
      echo "  Datei: ft_print_combn.c"
      ;;
  esac

  echo ""
  echo -e "${DIM}Schreibe deinen Code in: ${EXAM_WORKDIR}/${task}.c${RESET}"
}

grade_task() {
  local task=$1
  local c_file="$EXAM_WORKDIR/${task}.c"
  local tmpdir
  tmpdir=$(mktemp -d)
  # shellcheck disable=SC2064
  trap "rm -rf $tmpdir" RETURN

  echo -e "\n${BOLD}Bewertung: $task${RESET}"

  # Datei vorhanden?
  if [ ! -f "$c_file" ]; then
    echo -e "${RED}✗ Keine Datei gefunden: $c_file${RESET}"
    return 1
  fi

  # Norminette
  NORM_OK=true
  NORM_OUT=$(norminette -R CheckForbiddenSourceHeader "$c_file" 2>&1)
  if echo "$NORM_OUT" | grep -q "Error\|Warning"; then
    echo -e "${RED}✗ Norminette: Fehler (−20 Punkte Abzug)${RESET}"
    NORM_OK=false
  else
    echo -e "${GREEN}✓ Norminette OK${RESET}"
  fi

  # Main-Wrapper
  case "$task" in
    ft_putchar)
      cat > "$tmpdir/main.c" << 'EOF'
#include <unistd.h>
void ft_putchar(char c);
int main(void) { ft_putchar('X'); return 0; }
EOF
      EXPECTED="X"
      ;;
    ft_print_numbers)
      cat > "$tmpdir/main.c" << 'EOF'
#include <unistd.h>
void ft_print_numbers(void);
int main(void) { ft_print_numbers(); return 0; }
EOF
      EXPECTED="0123456789"
      ;;
    ft_is_negative)
      cat > "$tmpdir/main.c" << 'EOF'
#include <unistd.h>
void ft_is_negative(int n);
int main(void)
{
    ft_is_negative(-5);
    ft_is_negative(0);
    ft_is_negative(5);
    ft_is_negative(-2147483648);
    return 0;
}
EOF
      EXPECTED="NPPN"
      ;;
    ft_putnbr)
      cat > "$tmpdir/main.c" << 'EOF'
#include <unistd.h>
void ft_putnbr(int nb);
int main(void)
{
    ft_putnbr(0); write(1, "\n", 1);
    ft_putnbr(-42); write(1, "\n", 1);
    ft_putnbr(2147483647); write(1, "\n", 1);
    ft_putnbr(-2147483648); write(1, "\n", 1);
    return 0;
}
EOF
      EXPECTED="0
-42
2147483647
-2147483648"
      ;;
    ft_print_combn)
      cat > "$tmpdir/main.c" << 'EOF'
#include <unistd.h>
void ft_print_combn(int n);
int main(void) { ft_print_combn(2); return 0; }
EOF
      CHECK_START="01, 02"
      CHECK_END="89"
      EXPECTED=""  # Speziell behandelt unten
      ;;
  esac

  # Kompilieren
  if ! cc -Wall -Wextra -Werror "$c_file" "$tmpdir/main.c" -o "$tmpdir/a.out" 2>"$tmpdir/compile_err"; then
    echo -e "${RED}✗ Kompilierfehler:${RESET}"
    cat "$tmpdir/compile_err"
    return 1
  fi
  echo -e "${GREEN}✓ Kompiliert${RESET}"

  # Ausführen & vergleichen
  ACTUAL=$("$tmpdir/a.out" 2>/dev/null)

  if [ "$task" = "ft_print_combn" ]; then
    START_OK=false; END_OK=false
    echo "$ACTUAL" | grep -q "^$CHECK_START" && START_OK=true
    echo "$ACTUAL" | grep -q "$CHECK_END$"   && END_OK=true
    $START_OK && echo -e "${GREEN}✓ Ausgabe beginnt korrekt (01, 02, ...)${RESET}"
    $END_OK   && echo -e "${GREEN}✓ Ausgabe endet korrekt (...89)${RESET}"
    if ! $START_OK || ! $END_OK; then return 1; fi
  else
    # Normalisiere Zeilenenden
    ACTUAL_NORM=$(echo "$ACTUAL" | tr -d '\r')
    EXPECTED_NORM=$(echo "$EXPECTED" | tr -d '\r')
    if [ "$ACTUAL_NORM" = "$EXPECTED_NORM" ]; then
      echo -e "${GREEN}✓ Ausgabe korrekt${RESET}"
    else
      echo -e "${RED}✗ Ausgabe falsch${RESET}"
      echo -e "  Erwartet: $(echo "$EXPECTED" | head -c 50)"
      echo -e "  Bekommen: $(echo "$ACTUAL" | head -c 50)"
      return 1
    fi
  fi

  [ "$NORM_OK" = true ] && return 0 || return 2  # 2 = bestanden aber Norm-Fehler
}

# ─── Haupt-Exam-Loop ─────────────────────────────────────────────────────────

show_header
echo ""
echo -e "  ${BOLD}EXAM-REGELN:${RESET}"
echo -e "  • Kein Internet, kein Peer, kein Claude"
echo -e "  • Nur ${CYAN}write()${RESET} erlaubt (außer wo anders angegeben)"
echo -e "  • Kompilierung: ${CYAN}cc -Wall -Wextra -Werror${RESET}"
echo -e "  • Norminette: ${CYAN}-R CheckForbiddenSourceHeader${RESET}"
echo -e "  • Bestehen ab ${YELLOW}25/100${RESET}"
echo -e "  • Dauer: ${BOLD}${EXAM_TIME_MIN} Minuten${RESET}"
echo ""
echo -e "  Arbeitsverzeichnis wird erstellt unter: ${CYAN}$TOOL_ROOT/exam/session_*/...${RESET}"
echo ""
echo -ne "  ${BOLD}ENTER zum Starten${RESET} (oder Ctrl+C zum Abbrechen)... "
read -r

# Arbeitsverzeichnis für diese Session
SESSION_ID=$(date +%Y%m%d_%H%M%S)
EXAM_WORKDIR="$SCRIPT_DIR/session_$SESSION_ID"
mkdir -p "$EXAM_WORKDIR"

EXAM_START=$(date +%s)
EXAM_END=$((EXAM_START + EXAM_TIME_MIN * 60))
CURRENT_LEVEL=0
FINAL_SCORE=0
PASSED_LEVEL=-1

while [ $CURRENT_LEVEL -le $MAX_LEVEL ]; do
  # Timer prüfen
  NOW=$(date +%s)
  ELAPSED=$((NOW - EXAM_START))
  REMAINING=$((EXAM_END - NOW))

  if [ $REMAINING -le 0 ]; then
    echo -e "\n${RED}${BOLD}⏱  ZEIT ABGELAUFEN!${RESET}"
    break
  fi

  show_header
  show_timer $ELAPSED
  show_task $CURRENT_LEVEL
  echo ""
  echo -e "  ${DIM}Schreibe deinen Code, dann Enter drücken um zu bewerten.${RESET}"
  echo -e "  ${DIM}Oder 'skip' eingeben um aufzuhören (aktueller Score wird gespeichert).${RESET}"
  echo ""
  echo -ne "  [ENTER = bewerten | 'skip' = aufhören] "
  read -r INPUT

  if [ "$INPUT" = "skip" ]; then
    echo -e "\n${YELLOW}Exam beendet.${RESET}"
    break
  fi

  # Bewertung
  GRADE_RESULT=0
  grade_task "${LEVEL_TASKS[$CURRENT_LEVEL]}"
  GRADE_RESULT=$?

  if [ $GRADE_RESULT -eq 0 ]; then
    # Voll bestanden
    FINAL_SCORE="${LEVEL_SCORE[$CURRENT_LEVEL]}"
    PASSED_LEVEL=$CURRENT_LEVEL
    echo -e "\n${GREEN}${BOLD}✓ LEVEL $CURRENT_LEVEL BESTANDEN!${RESET} → Score jetzt: ${FINAL_SCORE}/100"
    CURRENT_LEVEL=$((CURRENT_LEVEL + 1))
    if [ $CURRENT_LEVEL -gt $MAX_LEVEL ]; then
      echo -e "${GREEN}${BOLD}🏆 ALLE LEVEL GESCHAFFT! 100/100!${RESET}"
      break
    fi
    echo -e "\n${CYAN}Weiter zu Level $CURRENT_LEVEL...${RESET}"
    sleep 2
  elif [ $GRADE_RESULT -eq 2 ]; then
    # Bestanden aber Norm-Fehler
    NORM_PENALTY_SCORE=$(( ${LEVEL_SCORE[$CURRENT_LEVEL]} - 20 ))
    FINAL_SCORE="$NORM_PENALTY_SCORE"
    PASSED_LEVEL=$CURRENT_LEVEL
    echo -e "\n${YELLOW}${BOLD}~ BESTANDEN (mit Norm-Abzug)${RESET} → Score: ${FINAL_SCORE}/100"
    CURRENT_LEVEL=$((CURRENT_LEVEL + 1))
    sleep 2
  else
    # Nicht bestanden
    echo -e "\n${RED}${BOLD}✗ LEVEL $CURRENT_LEVEL NICHT BESTANDEN.${RESET}"
    echo -e "  Aktueller Score bleibt: ${FINAL_SCORE}/100"
    echo ""
    echo -ne "  [ENTER = nochmal versuchen | 'skip' = Exam beenden] "
    read -r RETRY
    if [ "$RETRY" = "skip" ]; then
      break
    fi
    # Nochmal versuchen (selbe Level, Timer läuft weiter)
  fi
done

# ─── Ergebnis ────────────────────────────────────────────────────────────────
NOW=$(date +%s)
ELAPSED_TOTAL=$((NOW - EXAM_START))
MINS_USED=$((ELAPSED_TOTAL / 60))
SECS_USED=$((ELAPSED_TOTAL % 60))

show_header
echo ""
echo -e "  ${BOLD}═══ EXAM BEENDET ═══${RESET}"
echo ""
echo -e "  Score:     ${BOLD}${FINAL_SCORE}/100${RESET}"
echo -e "  Zeit:      ${MINS_USED}m ${SECS_USED}s"
echo -e "  Bestanden: $([ $FINAL_SCORE -ge 25 ] && echo "${GREEN}JA${RESET}" || echo "${RED}NEIN${RESET}")"
echo ""

if [ $FINAL_SCORE -ge 90 ]; then
  echo -e "  ${GREEN}${BOLD}🥇 OUTSTANDING – Du bist ein echter 42-Student!${RESET}"
elif [ $FINAL_SCORE -ge 75 ]; then
  echo -e "  ${GREEN}${BOLD}🥈 STARK – Sehr gutes Ergebnis!${RESET}"
elif [ $FINAL_SCORE -ge 50 ]; then
  echo -e "  ${YELLOW}${BOLD}🥉 SOLIDE – Bestanden, weiter üben!${RESET}"
elif [ $FINAL_SCORE -ge 25 ]; then
  echo -e "  ${YELLOW}Bestanden (Minimum erreicht). Mehr üben für nächste Runde!${RESET}"
else
  echo -e "  ${RED}Nicht bestanden. Kein Stress – das echte 42-Exam darf man wiederholen!${RESET}"
fi

# In progress.json eintragen
NOW_ISO=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
python3 << PYEOF
import json
from datetime import datetime

progress_path = "$PROGRESS"
score = int("$FINAL_SCORE")
now = "$NOW_ISO"

with open(progress_path, 'r') as f:
    p = json.load(f)

module = p['modules']['C00']
old_score = module.get('exam_score') or 0
module['exam_attempts'] = module.get('exam_attempts', 0) + 1

if score > old_score:
    module['exam_score'] = score
    print(f"  Neuer Bestwert: {score}/100!")
else:
    print(f"  Bestwert bleibt: {old_score}/100")

# Exam-XP: 10% des Scores
exam_xp = score // 10
p['xp'] = p.get('xp', 0) + exam_xp
p['weekly_xp'] = p.get('weekly_xp', 0) + exam_xp

# Badge für bestandenes Exam
if score >= 25:
    badge_id = f"C00_exam_passed"
    if badge_id not in p.get('badges_total', []):
        p.setdefault('badges_total', []).append(badge_id)
        module.setdefault('badges', []).append(badge_id)
        print(f"  🏅 Badge erhalten: {badge_id}")

p['updated'] = now
with open(progress_path, 'w') as f:
    json.dump(p, f, indent=2, ensure_ascii=False)
print(f"  XP +{exam_xp} → Gesamt: {p['xp']}")
PYEOF

echo ""
echo -e "  ${CYAN}Trophäenschrank: bash $SCRIPT_DIR/../scripts/trophy.sh${RESET}"
echo ""

# Arbeitsverzeichnis-Hinweis
echo -e "  ${DIM}Dein Code liegt in: $EXAM_WORKDIR${RESET}"
echo ""
