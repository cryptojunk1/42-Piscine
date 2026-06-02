#!/bin/bash
# =============================================================================
# 42 Lerntool – check.sh  (generisch, Multi-Modul)
# Usage: bash check.sh <MODULE> <exercise_name|ex_id>
#   z.B.: bash check.sh C00 ft_putchar
#         bash check.sh C00 ex00
#         bash check.sh Shell00 ex04
# =============================================================================

# KEIN set -e: Norminette/cc geben bei Fehlern Exit != 0, das behandeln wir selbst
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOL_ROOT="$(dirname "$SCRIPT_DIR")"
PROGRESS_JSON="$(dirname "$TOOL_ROOT")/progress.json"
export PATH="$PATH:$HOME/.local/bin"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

# ─── Argumente ───────────────────────────────────────────────────────────────
if [ $# -lt 2 ]; then
  echo -e "${RED}Usage: bash check.sh <MODULE> <exercise_name|ex_id>${RESET}"
  echo "  Beispiele: bash check.sh C00 ft_putchar"
  echo "             bash check.sh Shell00 ex04"
  exit 1
fi

MODULE="$1"
ARG="$2"

# ─── Modul-JSON laden ────────────────────────────────────────────────────────
MODULE_LOWER=$(echo "$MODULE" | tr '[:upper:]' '[:lower:]')
JSON_FILE="$TOOL_ROOT/subjects/${MODULE_LOWER}_exercises.json"
if [ ! -f "$JSON_FILE" ]; then
  echo -e "${RED}Kein Subject-JSON für Modul '$MODULE': $JSON_FILE${RESET}"
  exit 1
fi

# ─── Übung auflösen ──────────────────────────────────────────────────────────
EX_JSON=$(python3 -c "
import json, sys
data = json.load(open('$JSON_FILE', encoding='utf-8'))
arg = '$ARG'.lower()
for ex in data['exercises']:
    if ex['id'].lower() == arg or ex['name'].lower() == arg:
        print(json.dumps(ex))
        sys.exit(0)
sys.exit(1)
" 2>/dev/null)

if [ -z "$EX_JSON" ]; then
  echo -e "${RED}Unbekannte Übung: '$ARG' in Modul $MODULE${RESET}"
  python3 -c "
import json
d = json.load(open('$JSON_FILE', encoding='utf-8'))
for e in d['exercises']:
    print(f\"  {e['id']}  {e['name']}\")
"
  exit 1
fi

EX_ID=$(   echo "$EX_JSON" | python3 -c "import json,sys; e=json.load(sys.stdin); print(e['id'])")
EX_NAME=$( echo "$EX_JSON" | python3 -c "import json,sys; e=json.load(sys.stdin); print(e['name'])")
EX_TYPE=$( echo "$EX_JSON" | python3 -c "import json,sys; e=json.load(sys.stdin); print(e.get('type','c'))")
EX_DIR=$(  echo "$EX_JSON" | python3 -c "import json,sys; e=json.load(sys.stdin); print(e.get('directory','').rstrip('/'))")
EX_FILES=$(echo "$EX_JSON" | python3 -c "import json,sys; e=json.load(sys.stdin); print(' '.join(e.get('files',[])))")

PEER_DIR="$TOOL_ROOT/peer/$MODULE/$EX_DIR"
CHECKER_DIR="$TOOL_ROOT/subjects/$MODULE/$EX_ID"

echo -e "\n${BOLD}════════════════════════════════════════${RESET}"
echo -e "${BOLD}  42 CHECK: $MODULE / $EX_ID – $EX_NAME${RESET}"
echo -e "${BOLD}════════════════════════════════════════${RESET}"
echo -e "Verzeichnis: ${CYAN}$PEER_DIR${RESET}\n"

# Prüfen ob Dateien vorhanden
for f in $EX_FILES; do
  if [ ! -f "$PEER_DIR/$f" ]; then
    echo -e "${YELLOW}⚠ $f noch nicht vorhanden.${RESET}"
    echo -e "Anlegen: ${CYAN}bash $SCRIPT_DIR/new.sh $MODULE $EX_ID${RESET}"
    exit 1
  fi
done

# ─── Ergebnis-Banner ─────────────────────────────────────────────────────────
print_result() {
  local tp="$1" tt="$2" score="$3"
  echo ""
  echo -e "${BOLD}════════════════════════════════════════${RESET}"
  local grade color
  if   [ "$score" -ge 80 ]; then grade="Gold 🥇";            color=$GREEN
  elif [ "$score" -ge 60 ]; then grade="Silber 🥈";          color=$YELLOW
  elif [ "$score" -ge 40 ]; then grade="Bronze 🥉";          color=$YELLOW
  else                            grade="Nicht bestanden ✗";  color=$RED
  fi
  echo -e "  Tests: ${tp}/${tt}  |  Score: ${BOLD}${color}${score}/100${RESET}  |  $grade"
  echo -e "${BOLD}════════════════════════════════════════${RESET}"

  if [ "${NO_CHAIN:-0}" != "1" ] && [ "$score" -ge 1 ]; then
    echo ""
    if bash "$SCRIPT_DIR/update_progress.sh" "$MODULE" "$EX_NAME" "$score" >/dev/null 2>&1; then
      echo -e "${GREEN}✓ Fortschritt eingetragen${RESET}"
    else
      echo -e "${YELLOW}⚠ Fortschritt konnte nicht eingetragen werden${RESET}"
    fi
    python3 "$SCRIPT_DIR/generate_dashboard.py" >/dev/null 2>&1 \
      && echo -e "${GREEN}✓ Dashboard aktualisiert${RESET}" || true
  fi

  echo ""
  if [ "$score" -ge 80 ]; then
    echo -e "${GREEN}${BOLD}Bestanden! 🎉${RESET}"
    echo -e "\n${CYAN}Committen (selbst – Git lernt man durch Tun):${RESET}"
    echo -e "  ${BOLD}cd \"$TOOL_ROOT\" && git add -A && git commit -m \"$MODULE: $EX_NAME ($score/100)\" && git push${RESET}"
  elif [ "$score" -ge 40 ]; then
    echo -e "${YELLOW}Fast! Hinweis-Stufe aufdecken oder Peer fragen.${RESET}"
  else
    echo -e "${RED}Noch nicht. Zurück zum Code!${RESET}"
  fi
  exit $([ "$score" -ge 80 ] && echo 0 || echo 1)
}

# ─── Shell-Checker ───────────────────────────────────────────────────────────
check_shell() {
  local checker="$CHECKER_DIR/checker.sh"
  if [ ! -f "$checker" ]; then
    echo -e "${RED}checker.sh fehlt: $checker${RESET}"; exit 1
  fi
  # checker.sh gibt "SCORE:N/M" als letzte Zeile aus
  local result exit_code score=0 tp=0 tt=1
  result=$(bash "$checker" "$PEER_DIR" "$EX_NAME" 2>&1)
  exit_code=$?
  echo "$result"
  local score_line
  score_line=$(echo "$result" | grep "^SCORE:" | tail -1)
  if [ -n "$score_line" ]; then
    tp=$(echo "$score_line" | cut -d: -f2 | cut -d/ -f1)
    tt=$(echo "$score_line" | cut -d: -f2 | cut -d/ -f2)
    [ "$tt" -gt 0 ] && score=$(( (tp * 100) / tt )) || score=0
  else
    [ "$exit_code" -eq 0 ] && score=100 && tp=1 || score=0 && tp=0
  fi
  print_result "$tp" "$tt" "$score"
}

# ─── C-Checker ───────────────────────────────────────────────────────────────
check_c() {
  local score=100 norm_ok=true tp=0 tt=0

  # 1. Norminette
  echo -e "${BOLD}[1/3] Norminette${RESET}"
  local norm_out=""
  for f in $EX_FILES; do
    norm_out+=$(norminette -R CheckForbiddenSourceHeader "$PEER_DIR/$f" 2>&1)$'\n'
  done
  if echo "$norm_out" | grep -qE "^Error|^Warning"; then
    echo -e "${RED}✗ Norminette-Fehler:${RESET}"
    echo "$norm_out"
    norm_ok=false
  else
    echo -e "${GREEN}✓ Norminette OK${RESET}"
  fi

  # 2. Kompilierung
  echo -e "\n${BOLD}[2/3] Kompilierung (cc -Wall -Wextra -Werror)${RESET}"
  local cc_bin
  cc_bin="$(command -v cc || command -v gcc || command -v clang || true)"
  if [ -z "$cc_bin" ]; then
    echo -e "${RED}✗ Kein C-Compiler gefunden!${RESET}"
    echo -e "${YELLOW}  sudo apt update && sudo apt install -y build-essential${RESET}"
    exit 1
  fi

  local checker_main="$CHECKER_DIR/checker_main.c"
  if [ ! -f "$checker_main" ]; then
    echo -e "${RED}✗ checker_main.c fehlt: $checker_main${RESET}"; exit 1
  fi

  local tmpdir
  tmpdir=$(mktemp -d)
  trap "rm -rf $tmpdir" EXIT

  local student_files=()
  for f in $EX_FILES; do student_files+=("$PEER_DIR/$f"); done

  local compile_out
  compile_out=$("$cc_bin" -Wall -Wextra -Werror \
    "${student_files[@]}" "$checker_main" \
    -o "$tmpdir/a.out" 2>&1)
  if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Kompilierfehler:${RESET}"
    echo "$compile_out"
    echo -e "\n${RED}Score: 0/100 (kompiliert nicht = Moulinette: 0)${RESET}"
    print_result 0 1 0
  fi
  echo -e "${GREEN}✓ Kompiliert sauber${RESET}"

  # 3. Tests
  echo -e "\n${BOLD}[3/3] Tests${RESET}"
  local check_mode
  check_mode=$(grep -m1 "CHECK_MODE:" "$checker_main" 2>/dev/null | sed 's/.*CHECK_MODE: *//' || echo "full")

  if [ "${check_mode:-full}" = "partial" ]; then
    local p_start p_end actual
    p_start=$(awk '/EXPECTED_PARTIAL_START/{f=1;next}/\*\//{if(f)exit}f{print}' "$checker_main" | head -1)
    p_end=$(  awk '/EXPECTED_PARTIAL_END/{f=1;next}/\*\//{if(f)exit}f{print}' "$checker_main" | head -1)
    actual=$("$tmpdir/a.out" 2>/dev/null)
    tt=2
    if echo "$actual" | grep -qF "$p_start"; then
      echo -e "  ${GREEN}✓ Anfang korrekt: $(echo "$p_start" | head -c 40)...${RESET}"
      tp=$((tp + 1))
    else
      echo -e "  ${RED}✗ Anfang falsch.${RESET}"
      echo -e "    Erwartet: $(echo "$p_start" | head -c 40)"
      echo -e "    Bekommen: $(echo "$actual"  | head -c 40)"
    fi
    if echo "$actual" | grep -qF "$p_end"; then
      echo -e "  ${GREEN}✓ Ende korrekt: ...$(echo "$p_end" | head -c 40)${RESET}"
      tp=$((tp + 1))
    else
      echo -e "  ${RED}✗ Ende falsch.${RESET}"
      echo -e "    Erwartet: $(echo "$p_end"  | tail -c 40)"
      echo -e "    Bekommen: $(echo "$actual" | tail -c 40)"
    fi
  else
    # Exakter Output-Vergleich
    local expected actual
    expected=$(awk '/EXPECTED_OUTPUT/{f=1;next}/\*\//{if(f)exit}f{print}' "$checker_main")
    actual=$("$tmpdir/a.out" 2>/dev/null)
    tt=1
    if [ "$actual" = "$expected" ]; then
      echo -e "  ${GREEN}✓ Output korrekt${RESET}"
      tp=1
    else
      echo -e "  ${RED}✗ Output falsch${RESET}"
      echo -e "  Erwartet:"
      echo "$expected" | head -6 | sed 's/^/    /'
      echo -e "  Bekommen:"
      echo "$actual"   | head -6 | sed 's/^/    /'
    fi
  fi

  # Score: 30% Norm-Abzug wenn fehlgeschlagen, Rest aus Tests
  local test_pct=0
  [ "$tt" -gt 0 ] && test_pct=$(( (tp * 100) / tt ))
  if [ "$norm_ok" = true ]; then
    score=$test_pct
  else
    score=$(( (test_pct * 70) / 100 ))
  fi

  print_result "$tp" "$tt" "$score"
}

# ─── Dispatch ────────────────────────────────────────────────────────────────
if [ "$EX_TYPE" = "shell" ]; then
  check_shell
else
  check_c
fi
