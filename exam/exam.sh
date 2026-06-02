#!/bin/bash
# =============================================================================
# 42 Lerntool – exam.sh  (generisch, Multi-Modul)
# Usage: bash exam.sh [--time <min>] [--module <ID>]
# =============================================================================

EXAM_TIME_MIN=60
MODULE="C00"
while [[ $# -gt 0 ]]; do
  case "$1" in --time) EXAM_TIME_MIN="$2"; shift 2 ;; --module) MODULE="$2"; shift 2 ;; *) shift ;; esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOL_ROOT="$(dirname "$SCRIPT_DIR")"
PROGRESS="$(dirname "$TOOL_ROOT")/progress.json"
SUBJECTS="$TOOL_ROOT/subjects"
export PATH="$PATH:$HOME/.local/bin"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BLUE='\033[0;34m'; MAGENTA='\033[0;35m'
BOLD='\033[1m'; DIM='\033[2m'; RESET='\033[0m'

# ─── Modul-JSON laden ────────────────────────────────────────────────────────
MODULE_LOWER=$(echo "$MODULE" | tr '[:upper:]' '[:lower:]')
JSON_FILE="$SUBJECTS/${MODULE_LOWER}_exercises.json"
if [ ! -f "$JSON_FILE" ]; then
  echo -e "${RED}Kein Subject-JSON für '$MODULE'${RESET}"; exit 1
fi

# 5 Exam-Level aus JSON bestimmen (Indices 0,2,4,6,8 – oder alle wenn < 10)
# Wählt gleichmäßig verteilt aus der Übungsliste
EXAM_TASKS_JSON=$(python3 -c "
import json, sys
d = json.load(open('$JSON_FILE', encoding='utf-8'))
exs = d['exercises']
n   = len(exs)
if n >= 5:
    step = max(1, n // 5)
    picks = [exs[min(i*step, n-1)] for i in range(5)]
    # Stelle sicher dass letzter Pick das letzte Element ist
    picks[4] = exs[n-1]
else:
    picks = exs[:n] + [exs[-1]] * (5 - n)
for p in picks:
    print(f\"{p['id']}|{p['name']}|{p.get('prototype','')}\")
")

mapfile -t EXAM_LINES <<< "$EXAM_TASKS_JSON"
LEVEL_SCORES=(25 50 75 90 100)
MAX_LEVEL=4

# Exam-Arbeitsverzeichnis (temporär, isoliert vom Peer-Code)
EXAM_WORKDIR=$(mktemp -d /tmp/42exam_XXXXXX)
trap "rm -rf $EXAM_WORKDIR" EXIT

EXAM_START=$(date +%s)

# ─── Banner ──────────────────────────────────────────────────────────────────
show_header() {
  clear
  echo -e "${BOLD}${BLUE}"
  echo "  ╔══════════════════════════════════════════════════╗"
  printf "  ║     42 PISCINE EXAM – %-26s║\n" "$MODULE              "
  echo "  ║          *** KEIN TUTOR-ZUGRIFF ***              ║"
  echo -e "  ╚══════════════════════════════════════════════════╝${RESET}"
}

show_timer() {
  local elapsed=$1
  local remaining=$(( EXAM_TIME_MIN * 60 - elapsed ))
  local mins=$((remaining / 60)) secs=$((remaining % 60))
  if   [ $remaining -le 300 ]; then echo -e "${RED}${BOLD}⏱  VERBLEIBEND: ${mins}m ${secs}s${RESET}"
  elif [ $remaining -le 600 ]; then echo -e "${YELLOW}${BOLD}⏱  Verbleibend: ${mins}m ${secs}s${RESET}"
  else                               echo -e "${CYAN}⏱  Verbleibend: ${mins}m ${secs}s${RESET}"
  fi
}

check_time() {
  local elapsed=$(( $(date +%s) - EXAM_START ))
  if [ $elapsed -ge $(( EXAM_TIME_MIN * 60 )) ]; then
    echo -e "\n${RED}${BOLD}⏰ ZEIT ABGELAUFEN!${RESET}"
    finalize_exam 0
  fi
}

# ─── Aufgabe anzeigen ────────────────────────────────────────────────────────
show_task() {
  local level=$1
  IFS='|' read -r ex_id ex_name proto <<< "${EXAM_LINES[$level]}"
  local pts="${LEVEL_SCORES[$level]}"
  echo -e "\n${BOLD}${MAGENTA}════ LEVEL $level – $ex_name (→ $pts Punkte) ════${RESET}\n"
  echo -e "${BOLD}Aufgabe:${RESET} Schreibe ${CYAN}$ex_name${RESET}"
  [ -n "$proto" ] && echo -e "\n  ${proto}\n"
  # Beschreibung aus JSON
  python3 -c "
import json
d = json.load(open('$JSON_FILE', encoding='utf-8'))
e = next((x for x in d['exercises'] if x['id']=='$ex_id'), None)
if e:
    desc = e.get('description_de') or e.get('description','')
    print('  ' + desc[:300])
    af = e.get('allowed_functions',[])
    if af: print(f\"  Erlaubt: {', '.join(af)}\")
    fs = e.get('files',[])
    if fs: print(f\"  Dateien: {', '.join(fs)}\")
" 2>/dev/null
  echo -e "\n${DIM}Code schreiben in: ${CYAN}$EXAM_WORKDIR/${ex_name}.c${RESET}"
}

# ─── Bewertung ───────────────────────────────────────────────────────────────
grade_task() {
  local level=$1
  IFS='|' read -r ex_id ex_name proto <<< "${EXAM_LINES[$level]}"
  local c_file="$EXAM_WORKDIR/${ex_name}.c"
  local checker_main="$SUBJECTS/$MODULE/$ex_id/checker_main.c"
  local score=0

  echo -e "\n${BOLD}Bewertung: $ex_name${RESET}"

  # Datei vorhanden?
  if [ ! -f "$c_file" ]; then
    echo -e "${RED}✗ Keine Datei: $c_file${RESET}"; return 1
  fi

  # Norminette
  local norm_ok=true
  local norm_out
  norm_out=$(norminette -R CheckForbiddenSourceHeader "$c_file" 2>&1)
  if echo "$norm_out" | grep -qE "^Error|^Warning"; then
    echo -e "${RED}✗ Norminette: Fehler (−20%)${RESET}"; norm_ok=false
  else
    echo -e "${GREEN}✓ Norminette OK${RESET}"
  fi

  # Compile
  local cc_bin; cc_bin="$(command -v cc || command -v gcc || command -v clang || true)"
  if [ -z "$cc_bin" ]; then echo -e "${RED}Kein Compiler!${RESET}"; return 1; fi

  # Fallback: wenn kein checker_main.c, einfacher Compile-Test
  local tmpdir; tmpdir=$(mktemp -d); trap "rm -rf $tmpdir" RETURN

  if [ -f "$checker_main" ]; then
    local compile_out
    compile_out=$("$cc_bin" -Wall -Wextra -Werror "$c_file" "$checker_main" -o "$tmpdir/a.out" 2>&1)
  else
    local compile_out
    compile_out=$("$cc_bin" -Wall -Wextra -Werror -c "$c_file" -o "$tmpdir/a.o" 2>&1)
  fi

  if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Kompilierfehler:${RESET}"
    echo "$compile_out"
    return 1
  fi
  echo -e "${GREEN}✓ Kompiliert${RESET}"

  # Tests (nur wenn checker_main vorhanden)
  if [ -f "$checker_main" ] && [ -f "$tmpdir/a.out" ]; then
    local check_mode
    check_mode=$(grep -m1 "CHECK_MODE:" "$checker_main" 2>/dev/null | sed 's/.*CHECK_MODE: *//' || echo "full")
    local actual; actual=$("$tmpdir/a.out" 2>/dev/null)
    local test_ok=false

    if [ "${check_mode:-full}" = "partial" ]; then
      local p_start; p_start=$(awk '/EXPECTED_PARTIAL_START/{f=1;next}/\*\//{if(f)exit}f{print}' "$checker_main" | head -1)
      local p_end;   p_end=$(  awk '/EXPECTED_PARTIAL_END/{f=1;next}/\*\//{if(f)exit}f{print}' "$checker_main" | head -1)
      echo "$actual" | grep -qF "$p_start" && echo "$actual" | grep -qF "$p_end" && test_ok=true
    else
      local expected; expected=$(awk '/EXPECTED_OUTPUT/{f=1;next}/\*\//{if(f)exit}f{print}' "$checker_main")
      [ "$actual" = "$expected" ] && test_ok=true
    fi

    if $test_ok; then
      echo -e "${GREEN}✓ Tests bestanden${RESET}"
      score=100
    else
      echo -e "${RED}✗ Tests fehlgeschlagen${RESET}"
      echo "  Erwartet: $(echo "$expected" 2>/dev/null | head -1 | head -c 60)"
      echo "  Bekommen: $(echo "$actual" | head -1 | head -c 60)"
      score=0
    fi
  else
    # Nur Compile-Test
    score=80
  fi

  # Norm-Abzug
  [ "$norm_ok" = false ] && score=$(( score * 80 / 100 ))

  echo -e "${BOLD}Score: ${score}/100${RESET}"
  [ $score -ge 80 ]
}

# ─── Abschluss ───────────────────────────────────────────────────────────────
finalize_exam() {
  local max_level_reached=$1
  local final_score="${LEVEL_SCORES[$max_level_reached]:-0}"

  show_header
  echo -e "\n${BOLD}${MAGENTA}══════ EXAM ABGESCHLOSSEN ══════${RESET}"
  echo -e "  Modul:       $MODULE"
  echo -e "  Bestanden bis Level: $max_level_reached von $MAX_LEVEL"
  echo -e "  Finaler Score: ${BOLD}${final_score}/100${RESET}"
  echo ""

  if   [ $final_score -ge 80 ]; then echo -e "${GREEN}${BOLD}🎉 BESTANDEN! Glückwunsch!${RESET}"
  elif [ $final_score -ge 25 ]; then echo -e "${YELLOW}${BOLD}Teilweise bestanden.${RESET}"
  else                                echo -e "${RED}${BOLD}Nicht bestanden.${RESET}"
  fi

  # Ergebnis in progress.json eintragen
  python3 - "$PROGRESS" "$MODULE" "$final_score" "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" << 'PY'
import json, sys
prog_path, module, score_str, now = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
score = int(score_str)
try:
    p = json.load(open(prog_path, encoding="utf-8"))
    if module not in p["modules"]:
        p["modules"][module] = {"status": "in_progress", "exam_score": None,
                                 "exam_attempts": 0, "badges": [], "certificate": None, "exercises": {}}
    m = p["modules"][module]
    m["exam_attempts"] = m.get("exam_attempts", 0) + 1
    if m.get("exam_score") is None or score > m["exam_score"]:
        m["exam_score"] = score
    if score >= 25:
        m["status"] = "completed"
    p["updated"] = now
    json.dump(p, open(prog_path, "w", encoding="utf-8"), indent=2, ensure_ascii=False)
    print(f"  Exam-Score {score}/100 in progress.json eingetragen.")
except Exception as e:
    print(f"  Warnung: progress.json konnte nicht aktualisiert werden: {e}")
PY

  echo ""
  echo -e "${DIM}Dein Exam-Workdir (zum Nachschauen): $EXAM_WORKDIR${RESET}"
  trap - EXIT  # Workdir nicht löschen nach Exam
  exit $([ $final_score -ge 25 ] && echo 0 || echo 1)
}

# ─── Haupt-Loop ──────────────────────────────────────────────────────────────
show_header
echo -e "\n${BOLD}Modul: $MODULE  |  Zeit: ${EXAM_TIME_MIN} Minuten  |  5 Level${RESET}"
echo -e "${DIM}Jedes Level ist schwerer als das vorherige.${RESET}"
echo -e "${DIM}Dein Workdir: $EXAM_WORKDIR${RESET}"
echo -e "\n${YELLOW}${BOLD}ACHTUNG: KEIN Tutor, KEINE Hinweise, KEIN Internet (Ehre!).${RESET}"
echo -e "${YELLOW}Benutze NUR: man-Seiten, eigenes Wissen.${RESET}"
echo ""
read -rp "  ${BOLD}[Enter] zum Starten ...${RESET}"
EXAM_START=$(date +%s)

CURRENT_LEVEL=0
while [ $CURRENT_LEVEL -le $MAX_LEVEL ]; do
  check_time
  show_header
  show_timer $(( $(date +%s) - EXAM_START ))
  show_task $CURRENT_LEVEL

  IFS='|' read -r ex_id ex_name proto <<< "${EXAM_LINES[$CURRENT_LEVEL]}"
  local_c_file="$EXAM_WORKDIR/${ex_name}.c"
  echo ""

  while true; do
    check_time
    echo -e "\n  ${BOLD}e${RESET}) Editor öffnen  ${BOLD}c${RESET}) Abgeben / Prüfen  ${BOLD}s${RESET}) Überspringen"
    read -rp "  > " act
    case "$act" in
      e|E)
        local ed="${EDITOR:-nano}"
        command -v nano >/dev/null 2>&1 && ed="nano"
        "$ed" "$local_c_file"
        ;;
      c|C)
        if grade_task $CURRENT_LEVEL; then
          echo -e "\n${GREEN}${BOLD}Level $CURRENT_LEVEL bestanden! Weiter zu Level $((CURRENT_LEVEL+1))...${RESET}"
          sleep 2
          CURRENT_LEVEL=$((CURRENT_LEVEL + 1))
          break
        else
          echo -e "\n${RED}Nicht bestanden. Weiter üben oder überspringen.${RESET}"
        fi
        ;;
      s|S)
        echo -e "${YELLOW}Level $CURRENT_LEVEL übersprungen.${RESET}"
        finalize_exam $((CURRENT_LEVEL > 0 ? CURRENT_LEVEL - 1 : 0))
        ;;
    esac
  done
done

finalize_exam $MAX_LEVEL
