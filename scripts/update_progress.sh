#!/bin/bash
# =============================================================================
# 42 Lerntool – update_progress.sh
# Trägt Ergebnis einer Übung in progress.json ein + vergibt XP/Badges
# Usage: bash update_progress.sh <exercise_name> <score> [hint_level]
#   z.B.: bash update_progress.sh ft_putchar 100
#         bash update_progress.sh ft_print_comb 75 2
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOL_ROOT="$(dirname "$SCRIPT_DIR")"
PROGRESS="$(dirname "$TOOL_ROOT")/progress.json"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

# Prüfe Python (für JSON-Manipulation)
if ! command -v python3 &>/dev/null; then
  echo -e "${RED}python3 nicht gefunden${RESET}"; exit 1
fi

EX_NAME="${1:-}"
SCORE="${2:-}"
HINT_LEVEL="${3:-0}"

if [ -z "$EX_NAME" ] || [ -z "$SCORE" ]; then
  echo -e "${RED}Usage: bash update_progress.sh <exercise_name> <score> [hint_level]${RESET}"
  exit 1
fi

# XP-Tabelle je Übung
declare -A XP_TABLE=(
  ["ft_putchar"]=20
  ["ft_print_alphabet"]=25
  ["ft_print_reverse_alphabet"]=25
  ["ft_print_numbers"]=25
  ["ft_is_negative"]=30
  ["ft_print_comb"]=50
  ["ft_print_comb2"]=60
  ["ft_putnbr"]=60
  ["ft_print_combn"]=80
)
BASE_XP="${XP_TABLE[$EX_NAME]:-20}"

# XP skaliert mit Score (Score 100 = volle XP, Score 60 = 60% XP)
EARNED_XP=$(( (BASE_XP * SCORE) / 100 ))

# Grade bestimmen
if [ "$SCORE" -ge 80 ]; then
  if [ "$SCORE" -ge 100 ] && [ "$HINT_LEVEL" -le 1 ]; then
    GRADE="gold"
  elif [ "$SCORE" -ge 80 ]; then
    GRADE="silver"
  fi
elif [ "$SCORE" -ge 60 ]; then
  GRADE="bronze"
else
  GRADE="null"
fi

NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

python3 << PYEOF
import json, sys
from datetime import datetime

progress_path = "$PROGRESS"
ex_name = "$EX_NAME"
score = int("$SCORE")
hint_level = int("$HINT_LEVEL")
earned_xp = int("$EARNED_XP")
grade = "$GRADE"
now = "$NOW"

with open(progress_path, 'r') as f:
    p = json.load(f)

ex = p['modules']['C00']['exercises'].get(ex_name)
if ex is None:
    print(f"Übung {ex_name} nicht in progress.json gefunden!")
    sys.exit(1)

# Update Übungs-Eintrag
ex['attempts'] = ex.get('attempts', 0) + 1
if ex['best_score'] is None or score > ex['best_score']:
    ex['best_score'] = score
if score >= 80:
    ex['done'] = True
ex['hint_level'] = max(ex.get('hint_level', 0), hint_level)
ex['grade'] = grade if grade != "null" else ex.get('grade')
ex['last_updated'] = now

# XP nur vergeben wenn Übung neu bestanden (nicht für Re-runs)
xp_gained = 0
if score >= 80:
    # Nur XP wenn vorher nicht done
    if ex['attempts'] == 1 or (ex.get('best_score', 0) == score):
        xp_gained = earned_xp
        p['xp'] = p.get('xp', 0) + xp_gained
        p['weekly_xp'] = p.get('weekly_xp', 0) + xp_gained

# Level berechnen (alle 200 XP ein Level)
xp = p['xp']
levels = [(0,'Piscine Newbie'),(200,'C Padawan'),(500,'Looper'),(900,'Pointeur'),(1400,'Récursif'),(2000,'Algo Mage')]
level = 0
title = 'Piscine Newbie'
for threshold, lv_title in levels:
    if xp >= threshold:
        level = levels.index((threshold, lv_title))
        title = lv_title
p['level'] = level
p['level_title'] = title

# Modul-Status aktualisieren
module = p['modules']['C00']
all_done = all(e['done'] for e in module['exercises'].values())
any_started = any(e['attempts'] > 0 for e in module['exercises'].values())
if all_done:
    module['status'] = 'completed'
elif any_started:
    module['status'] = 'in_progress'

# Weekly goal
if p.get('weekly_xp', 0) >= p.get('weekly_goal_xp', 100):
    p['week_goal_met'] = True

# Badge vergeben
badge_id = f"C00_{ex_name}_{grade}"
if grade in ('gold','silver','bronze') and badge_id not in p.get('badges_total', []):
    p.setdefault('badges_total', []).append(badge_id)
    module.setdefault('badges', []).append(badge_id)
    print(f"🏅 Neuer Badge: {badge_id}")

p['updated'] = now

with open(progress_path, 'w') as f:
    json.dump(p, f, indent=2, ensure_ascii=False)

print(f"✓ {ex_name}: Score={score}, Grade={grade}, XP+{xp_gained} (Gesamt: {p['xp']}), Level {p['level']} – {p['level_title']}")
PYEOF

echo ""
echo -e "${GREEN}${BOLD}progress.json aktualisiert.${RESET}"
echo -e "Trophäenschrank: ${CYAN}bash $SCRIPT_DIR/trophy.sh${RESET}"
