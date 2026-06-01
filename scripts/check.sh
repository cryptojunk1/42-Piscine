#!/bin/bash
# =============================================================================
# 42 Lerntool – check.sh
# Norminette + Compile + Test für eine C00-Übung
# Usage: bash check.sh <exercise_name_or_ex_id>
#   z.B.: bash check.sh ft_putchar
#         bash check.sh ex00
# =============================================================================

set -euo pipefail

# Pfade (relativ zu diesem Script → absolut auflösen)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOL_ROOT="$(dirname "$SCRIPT_DIR")"
PROGRESS_JSON="$(dirname "$TOOL_ROOT")/progress.json"

# Farben
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

# Norminette PATH
export PATH="$PATH:$HOME/.local/bin"

# ─── Argument auflösen ───────────────────────────────────────────────────────
if [ $# -lt 1 ]; then
  echo -e "${RED}Usage: bash check.sh <exercise_name|ex_id>${RESET}"
  echo "  Beispiele: ft_putchar  ft_print_comb  ex05"
  exit 1
fi

ARG="$1"
# ex00..ex08 → Name zuordnen
declare -A EX_MAP=(
  ["ex00"]="ft_putchar"          ["ft_putchar"]="ft_putchar"
  ["ex01"]="ft_print_alphabet"   ["ft_print_alphabet"]="ft_print_alphabet"
  ["ex02"]="ft_print_reverse_alphabet" ["ft_print_reverse_alphabet"]="ft_print_reverse_alphabet"
  ["ex03"]="ft_print_numbers"    ["ft_print_numbers"]="ft_print_numbers"
  ["ex04"]="ft_is_negative"      ["ft_is_negative"]="ft_is_negative"
  ["ex05"]="ft_print_comb"       ["ft_print_comb"]="ft_print_comb"
  ["ex06"]="ft_print_comb2"      ["ft_print_comb2"]="ft_print_comb2"
  ["ex07"]="ft_putnbr"           ["ft_putnbr"]="ft_putnbr"
  ["ex08"]="ft_print_combn"      ["ft_print_combn"]="ft_print_combn"
)
EX_NAME="${EX_MAP[$ARG]:-}"
if [ -z "$EX_NAME" ]; then
  echo -e "${RED}Unbekannte Übung: $ARG${RESET}"
  echo "Gültig: ft_putchar, ft_print_alphabet, ft_print_reverse_alphabet, ft_print_numbers,"
  echo "        ft_is_negative, ft_print_comb, ft_print_comb2, ft_putnbr, ft_print_combn"
  exit 1
fi

# Suche .c-Datei: peer/<name>/, CWD, oder irgendwo unter peer/
WORK_DIR="$SCRIPT_DIR/../peer"

# 1. Standardpfad: peer/<ex_name>/<ex_name>.c
if [ -f "$WORK_DIR/${EX_NAME}/${EX_NAME}.c" ]; then
  C_FILE="$WORK_DIR/${EX_NAME}/${EX_NAME}.c"
# 2. Im aktuellen Verzeichnis
elif [ -f "${EX_NAME}.c" ]; then
  C_FILE="$(pwd)/${EX_NAME}.c"
# 3. Irgendwo unter peer/ (rekursiv)
else
  C_FILE=$(find "$WORK_DIR" -name "${EX_NAME}.c" 2>/dev/null | head -1)
fi

if [ -z "$C_FILE" ]; then
  echo -e "${YELLOW}⚠ Datei ${EX_NAME}.c noch nicht vorhanden.${RESET}"
  echo ""
  echo -e "Lege sie jetzt an:"
  echo -e "  ${CYAN}bash $SCRIPT_DIR/new.sh $EX_NAME${RESET}"
  echo ""
  echo -e "Das erstellt die Datei mit Template + 42-Header unter:"
  echo -e "  ${CYAN}$WORK_DIR/${EX_NAME}/${EX_NAME}.c${RESET}"
  exit 1
fi

C_DIR=$(dirname "$C_FILE")
echo -e "\n${BOLD}════════════════════════════════════════${RESET}"
echo -e "${BOLD}  42 CHECK: $EX_NAME${RESET}"
echo -e "${BOLD}════════════════════════════════════════${RESET}"
echo -e "Datei: ${CYAN}$C_FILE${RESET}\n"

SCORE=100
NORM_OK=true
COMPILE_OK=true
TESTS_PASSED=0
TESTS_TOTAL=0

# ─── 1. Norminette ───────────────────────────────────────────────────────────
echo -e "${BOLD}[1/3] Norminette${RESET}"
NORM_OUT=$(norminette -R CheckForbiddenSourceHeader "$C_FILE" 2>&1)
if echo "$NORM_OUT" | grep -q "Error\|Warning"; then
  echo -e "${RED}✗ Norminette-Fehler:${RESET}"
  echo "$NORM_OUT"
  NORM_OK=false
  SCORE=$((SCORE - 30))
else
  echo -e "${GREEN}✓ Norminette OK${RESET}"
fi

# ─── 2. Kompilierung ─────────────────────────────────────────────────────────
echo -e "\n${BOLD}[2/3] Kompilierung (cc -Wall -Wextra -Werror)${RESET}"
TMPDIR_CHECK=$(mktemp -d)
trap "rm -rf $TMPDIR_CHECK" EXIT

# Main-Wrapper je Übung
case "$EX_NAME" in
  ft_putchar)
    MAIN_C="$TMPDIR_CHECK/main.c"
    cat > "$MAIN_C" << 'MAINEOF'
#include <unistd.h>
void ft_putchar(char c);
int main(void)
{
    ft_putchar('4');
    ft_putchar('2');
    write(1, "\n", 1);
    return (0);
}
MAINEOF
    ;;
  ft_print_alphabet)
    cat > "$TMPDIR_CHECK/main.c" << 'MAINEOF'
#include <unistd.h>
void ft_print_alphabet(void);
int main(void) { ft_print_alphabet(); write(1, "\n", 1); return (0); }
MAINEOF
    ;;
  ft_print_reverse_alphabet)
    cat > "$TMPDIR_CHECK/main.c" << 'MAINEOF'
#include <unistd.h>
void ft_print_reverse_alphabet(void);
int main(void) { ft_print_reverse_alphabet(); write(1, "\n", 1); return (0); }
MAINEOF
    ;;
  ft_print_numbers)
    cat > "$TMPDIR_CHECK/main.c" << 'MAINEOF'
#include <unistd.h>
void ft_print_numbers(void);
int main(void) { ft_print_numbers(); write(1, "\n", 1); return (0); }
MAINEOF
    ;;
  ft_is_negative)
    cat > "$TMPDIR_CHECK/main.c" << 'MAINEOF'
#include <unistd.h>
void ft_is_negative(int n);
int main(void)
{
    ft_is_negative(-1);
    ft_is_negative(0);
    ft_is_negative(42);
    ft_is_negative(-2147483648);
    write(1, "\n", 1);
    return (0);
}
MAINEOF
    ;;
  ft_print_comb)
    cat > "$TMPDIR_CHECK/main.c" << 'MAINEOF'
#include <unistd.h>
void ft_print_comb(void);
int main(void) { ft_print_comb(); write(1, "\n", 1); return (0); }
MAINEOF
    ;;
  ft_print_comb2)
    cat > "$TMPDIR_CHECK/main.c" << 'MAINEOF'
#include <unistd.h>
void ft_print_comb2(void);
int main(void) { ft_print_comb2(); write(1, "\n", 1); return (0); }
MAINEOF
    ;;
  ft_putnbr)
    cat > "$TMPDIR_CHECK/main.c" << 'MAINEOF'
#include <unistd.h>
void ft_putnbr(int nb);
int main(void)
{
    ft_putnbr(42); write(1, "\n", 1);
    ft_putnbr(-42); write(1, "\n", 1);
    ft_putnbr(0); write(1, "\n", 1);
    ft_putnbr(2147483647); write(1, "\n", 1);
    ft_putnbr(-2147483648); write(1, "\n", 1);
    return (0);
}
MAINEOF
    ;;
  ft_print_combn)
    cat > "$TMPDIR_CHECK/main.c" << 'MAINEOF'
#include <unistd.h>
void ft_print_combn(int n);
int main(void)
{
    ft_print_combn(2); write(1, "\n", 1);
    return (0);
}
MAINEOF
    ;;
esac

COMPILE_OUT=$(cc -Wall -Wextra -Werror "$C_FILE" "$TMPDIR_CHECK/main.c" -o "$TMPDIR_CHECK/a.out" 2>&1)
if [ $? -ne 0 ]; then
  echo -e "${RED}✗ Kompilierfehler:${RESET}"
  echo "$COMPILE_OUT"
  COMPILE_OK=false
  SCORE=0
  echo -e "\n${RED}Score: 0/100 (kompiliert nicht = Moulinette: 0)${RESET}"
  exit 1
else
  echo -e "${GREEN}✓ Kompiliert sauber${RESET}"
fi

# ─── 3. Tests ────────────────────────────────────────────────────────────────
echo -e "\n${BOLD}[3/3] Tests${RESET}"

run_test() {
  local test_id="$1"
  local expected="$2"
  local args="${3:-}"
  TESTS_TOTAL=$((TESTS_TOTAL + 1))

  local actual
  if [ -z "$args" ]; then
    actual=$("$TMPDIR_CHECK/a.out" 2>/dev/null | tr -d '\n')
  else
    actual=$("$TMPDIR_CHECK/a.out" $args 2>/dev/null | tr -d '\n')
  fi

  if [ "$actual" = "$expected" ]; then
    echo -e "  ${GREEN}✓ $test_id${RESET}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "  ${RED}✗ $test_id${RESET}"
    echo -e "    Erwartet: ${CYAN}$(echo "$expected" | head -c 60)${RESET}"
    echo -e "    Bekommen: ${YELLOW}$(echo "$actual" | head -c 60)${RESET}"
  fi
}

# Übungs-spezifische Tests
case "$EX_NAME" in
  ft_putchar)
    TESTS_TOTAL=1
    OUT=$("$TMPDIR_CHECK/a.out" 2>/dev/null | tr -d '\n')
    if [ "$OUT" = "42" ]; then
      echo -e "  ${GREEN}✓ ft_putchar('4') + ft_putchar('2') → \"42\"${RESET}"
      TESTS_PASSED=1
    else
      echo -e "  ${RED}✗ Erwartet \"42\", bekommen: \"$OUT\"${RESET}"
    fi
    ;;

  ft_print_alphabet)
    TESTS_TOTAL=1
    OUT=$("$TMPDIR_CHECK/a.out" 2>/dev/null | tr -d '\n')
    EXP="abcdefghijklmnopqrstuvwxyz"
    [ "$OUT" = "$EXP" ] && { echo -e "  ${GREEN}✓ Alphabet korrekt${RESET}"; TESTS_PASSED=1; } \
      || echo -e "  ${RED}✗ Erwartet: $EXP\n    Bekommen: $OUT${RESET}"
    ;;

  ft_print_reverse_alphabet)
    TESTS_TOTAL=1
    OUT=$("$TMPDIR_CHECK/a.out" 2>/dev/null | tr -d '\n')
    EXP="zyxwvutsrqponmlkjihgfedcba"
    [ "$OUT" = "$EXP" ] && { echo -e "  ${GREEN}✓ Reverse Alphabet korrekt${RESET}"; TESTS_PASSED=1; } \
      || echo -e "  ${RED}✗ Erwartet: $EXP\n    Bekommen: $OUT${RESET}"
    ;;

  ft_print_numbers)
    TESTS_TOTAL=1
    OUT=$("$TMPDIR_CHECK/a.out" 2>/dev/null | tr -d '\n')
    EXP="0123456789"
    [ "$OUT" = "$EXP" ] && { echo -e "  ${GREEN}✓ Zahlen korrekt${RESET}"; TESTS_PASSED=1; } \
      || echo -e "  ${RED}✗ Erwartet: $EXP\n    Bekommen: $OUT${RESET}"
    ;;

  ft_is_negative)
    TESTS_TOTAL=1
    OUT=$("$TMPDIR_CHECK/a.out" 2>/dev/null | tr -d '\n')
    EXP="NPPP"  # -1→N, 0→P, 42→P, INT_MIN→N... wait: N, P, P, N
    # Korrektur: -1→N, 0→P, 42→P, -2147483648→N → "NPPN"
    EXP="NPPN"
    [ "$OUT" = "$EXP" ] && { echo -e "  ${GREEN}✓ ft_is_negative korrekt (NPPN)${RESET}"; TESTS_PASSED=1; } \
      || echo -e "  ${RED}✗ Erwartet: $EXP\n    Bekommen: $OUT${RESET}"
    ;;

  ft_print_comb)
    TESTS_TOTAL=2
    OUT=$("$TMPDIR_CHECK/a.out" 2>/dev/null | tr -d '\n')
    # Prüfe Anfang und Ende
    if echo "$OUT" | grep -q "^012, 013"; then
      echo -e "  ${GREEN}✓ Anfang korrekt (012, 013, ...)${RESET}"; TESTS_PASSED=$((TESTS_PASSED+1))
    else
      echo -e "  ${RED}✗ Anfang falsch: $(echo $OUT | head -c 20)${RESET}"
    fi
    if echo "$OUT" | grep -q "789$"; then
      echo -e "  ${GREEN}✓ Ende korrekt (...789, kein trailing ', ')${RESET}"; TESTS_PASSED=$((TESTS_PASSED+1))
    else
      echo -e "  ${RED}✗ Ende falsch: $(echo $OUT | tail -c 20)${RESET}"
    fi
    ;;

  ft_print_comb2)
    TESTS_TOTAL=2
    OUT=$("$TMPDIR_CHECK/a.out" 2>/dev/null | tr -d '\n')
    if echo "$OUT" | grep -q "^00 01, 00 02"; then
      echo -e "  ${GREEN}✓ Anfang korrekt (00 01, 00 02, ...)${RESET}"; TESTS_PASSED=$((TESTS_PASSED+1))
    else
      echo -e "  ${RED}✗ Anfang falsch: $(echo $OUT | head -c 25)${RESET}"
    fi
    if echo "$OUT" | grep -q "98 99$"; then
      echo -e "  ${GREEN}✓ Ende korrekt (...98 99, kein trailing)${RESET}"; TESTS_PASSED=$((TESTS_PASSED+1))
    else
      echo -e "  ${RED}✗ Ende falsch: $(echo $OUT | tail -c 25)${RESET}"
    fi
    ;;

  ft_putnbr)
    TESTS_TOTAL=5
    OUT_LINES=$("$TMPDIR_CHECK/a.out" 2>/dev/null)
    EXPECTED=("42" "-42" "0" "2147483647" "-2147483648")
    LABELS=("42" "-42" "0" "INT_MAX" "INT_MIN")
    i=0
    while IFS= read -r line; do
      if [ "${EXPECTED[$i]:-}" = "$line" ]; then
        echo -e "  ${GREEN}✓ ft_putnbr(${LABELS[$i]}) → $line${RESET}"; TESTS_PASSED=$((TESTS_PASSED+1))
      else
        echo -e "  ${RED}✗ ft_putnbr(${LABELS[$i]}): erwartet '${EXPECTED[$i]:-}', bekommen '$line'${RESET}"
      fi
      i=$((i+1))
    done <<< "$OUT_LINES"
    ;;

  ft_print_combn)
    TESTS_TOTAL=2
    OUT=$("$TMPDIR_CHECK/a.out" 2>/dev/null | tr -d '\n')
    if echo "$OUT" | grep -q "^01, 02, 03"; then
      echo -e "  ${GREEN}✓ n=2 Anfang korrekt (01, 02, 03, ...)${RESET}"; TESTS_PASSED=$((TESTS_PASSED+1))
    else
      echo -e "  ${RED}✗ n=2 Anfang falsch: $(echo $OUT | head -c 20)${RESET}"
    fi
    if echo "$OUT" | grep -q "89$"; then
      echo -e "  ${GREEN}✓ n=2 Ende korrekt (...89, kein trailing)${RESET}"; TESTS_PASSED=$((TESTS_PASSED+1))
    else
      echo -e "  ${RED}✗ n=2 Ende falsch: $(echo $OUT | tail -c 20)${RESET}"
    fi
    ;;
esac

# ─── Ergebnis ────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}════════════════════════════════════════${RESET}"

# Score berechnen
if [ "$NORM_OK" = false ]; then
  SCORE=$((SCORE - 30))
fi
if [ $TESTS_TOTAL -gt 0 ]; then
  TEST_SCORE=$(( (TESTS_PASSED * 100) / TESTS_TOTAL ))
  # Normierte Gewichtung: 30% Norm, 70% Tests (falls Norm OK)
  if [ "$NORM_OK" = true ]; then
    SCORE=$TEST_SCORE
  else
    SCORE=$(( (TEST_SCORE * 70) / 100 ))
  fi
fi

if [ $SCORE -ge 80 ]; then
  GRADE="Gold 🥇"   ; COLOR=$GREEN
elif [ $SCORE -ge 60 ]; then
  GRADE="Silber 🥈" ; COLOR=$YELLOW
elif [ $SCORE -ge 40 ]; then
  GRADE="Bronze 🥉" ; COLOR=$YELLOW
else
  GRADE="Nicht bestanden ✗"; COLOR=$RED
fi

echo -e "  Tests: ${TESTS_PASSED}/${TESTS_TOTAL}  |  Score: ${BOLD}${COLOR}${SCORE}/100${RESET}  |  $GRADE"
echo -e "${BOLD}════════════════════════════════════════${RESET}"

# ─── Auto-Verkettung: Fortschritt eintragen + Dashboard aktualisieren ────────
# (Score wird automatisch übernommen – keine manuelle Eingabe mehr nötig)
if [ "${NO_CHAIN:-0}" != "1" ] && [ "$SCORE" -ge 1 ]; then
  echo ""
  if bash "$SCRIPT_DIR/update_progress.sh" "$EX_NAME" "$SCORE" >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Fortschritt eingetragen${RESET} (Score automatisch übernommen)"
  else
    echo -e "${YELLOW}⚠ Fortschritt konnte nicht eingetragen werden${RESET}"
  fi
  if command -v python3 >/dev/null 2>&1 \
     && python3 "$SCRIPT_DIR/generate_dashboard.py" >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Dashboard aktualisiert${RESET}"
  fi
fi

echo ""
if [ "$SCORE" -ge 80 ]; then
  echo -e "${GREEN}${BOLD}Bestanden! 🎉${RESET}"
  echo -e "\n${CYAN}Jetzt committen – mach das selbst, so lernst du Git:${RESET}"
  REPO_ROOT="$TOOL_ROOT"
  echo -e "  ${BOLD}cd \"$REPO_ROOT\"${RESET}"
  echo -e "  ${BOLD}git add -A${RESET}"
  echo -e "  ${BOLD}git commit -m \"C00: $EX_NAME bestanden ($SCORE/100)\"${RESET}"
  echo -e "  ${BOLD}git push${RESET}"
elif [ "$SCORE" -ge 40 ]; then
  echo -e "${YELLOW}Fast! Deck im Launcher (42) die nächste Hinweis-Stufe auf oder frag deinen Peer.${RESET}"
else
  echo -e "${RED}Noch nicht. Zurück zum Code – du schaffst das!${RESET}"
fi

exit $([ "$SCORE" -ge 80 ] && echo 0 || echo 1)
