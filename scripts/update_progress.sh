#!/bin/bash
# =============================================================================
# 42 Lerntool – update_progress.sh  (generisch, Multi-Modul)
# Usage: bash update_progress.sh <MODULE> <exercise_name> <score> [hint_level]
#   z.B.: bash update_progress.sh C00 ft_putchar 100
#         bash update_progress.sh Shell00 ex04 75 2
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOL_ROOT="$(dirname "$SCRIPT_DIR")"
PROGRESS="$(dirname "$TOOL_ROOT")/progress.json"

RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

if ! command -v python3 &>/dev/null; then
  echo -e "${RED}python3 nicht gefunden${RESET}"; exit 1
fi

MODULE="${1:-}"
EX_NAME="${2:-}"
SCORE="${3:-}"
HINT_LEVEL="${4:-0}"

if [ -z "$MODULE" ] || [ -z "$EX_NAME" ] || [ -z "$SCORE" ]; then
  echo -e "${RED}Usage: bash update_progress.sh <MODULE> <exercise_name> <score> [hint_level]${RESET}"
  exit 1
fi

# XP-Reward aus Modul-JSON lesen
MODULE_LOWER=$(echo "$MODULE" | tr '[:upper:]' '[:lower:]')
JSON_FILE="$TOOL_ROOT/subjects/${MODULE_LOWER}_exercises.json"
BASE_XP=$(python3 -c "
import json, sys
try:
    d = json.load(open('$JSON_FILE', encoding='utf-8'))
    arg = '$EX_NAME'.lower()
    for e in d['exercises']:
        if e['name'].lower() == arg or e['id'].lower() == arg:
            print(e.get('xp_reward', 20))
            sys.exit(0)
    print(20)
except Exception:
    print(20)
" 2>/dev/null)
BASE_XP="${BASE_XP:-20}"

EARNED_XP=$(( (BASE_XP * SCORE) / 100 ))
NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

if   [ "$SCORE" -ge 100 ]; then GRADE="gold"
elif [ "$SCORE" -ge 80  ]; then GRADE="silver"
elif [ "$SCORE" -ge 60  ]; then GRADE="bronze"
else                             GRADE="null"
fi

python3 << PYEOF
import json, sys

progress_path = "$PROGRESS"
module_id     = "$MODULE"
ex_name       = "$EX_NAME"
score         = int("$SCORE")
hint_level    = int("$HINT_LEVEL")
earned_xp     = int("$EARNED_XP")
grade         = "$GRADE"
now           = "$NOW"

with open(progress_path, 'r', encoding='utf-8') as f:
    p = json.load(f)

# Modul anlegen falls noch nicht vorhanden
if module_id not in p['modules']:
    p['modules'][module_id] = {
        "status": "in_progress",
        "exam_score": None,
        "exam_attempts": 0,
        "badges": [],
        "certificate": None,
        "exercises": {}
    }

module = p['modules'][module_id]

# Übungs-Eintrag anlegen falls nicht vorhanden
if ex_name not in module['exercises']:
    module['exercises'][ex_name] = {
        "done": False, "attempts": 0,
        "hint_level": 0, "best_score": None,
        "grade": None, "last_updated": None
    }

ex = module['exercises'][ex_name]

# War die Übung vorher noch nicht done?
was_new_pass = (not ex['done']) and score >= 80

ex['attempts'] = ex.get('attempts', 0) + 1
if ex['best_score'] is None or score > ex['best_score']:
    ex['best_score'] = score
if score >= 80:
    ex['done'] = True
ex['hint_level'] = max(ex.get('hint_level', 0), hint_level)
ex['grade'] = grade if grade != 'null' else ex.get('grade')
ex['last_updated'] = now

# XP nur für neuen Erfolg
xp_gained = 0
if was_new_pass:
    xp_gained = earned_xp
    p['xp'] = p.get('xp', 0) + xp_gained
    p['weekly_xp'] = p.get('weekly_xp', 0) + xp_gained

# Level (alle 200 XP)
xp = p['xp']
levels = [
    (0,    'Piscine Newbie'),
    (200,  'C Padawan'),
    (500,  'Looper'),
    (900,  'Pointeur'),
    (1400, 'Récursif'),
    (2000, 'Algo Mage')
]
level = 0; title = 'Piscine Newbie'
for i, (threshold, lv_title) in enumerate(levels):
    if xp >= threshold:
        level = i; title = lv_title
p['level'] = level
p['level_title'] = title

# Modul-Status
all_done     = all(e['done'] for e in module['exercises'].values())
any_started  = any(e.get('attempts', 0) > 0 for e in module['exercises'].values())
if all_done:
    module['status'] = 'completed'
elif any_started:
    module['status'] = 'in_progress'

# Weekly goal
if p.get('weekly_xp', 0) >= p.get('weekly_goal_xp', 100):
    p['week_goal_met'] = True

# Badge
badge_id = f"{module_id}_{ex_name}_{grade}"
if grade in ('gold', 'silver', 'bronze') and was_new_pass:
    if badge_id not in p.get('badges_total', []):
        p.setdefault('badges_total', []).append(badge_id)
        module.setdefault('badges', []).append(badge_id)
        print(f"🏅 Neuer Badge: {badge_id}")

p['updated'] = now

with open(progress_path, 'w', encoding='utf-8') as f:
    json.dump(p, f, indent=2, ensure_ascii=False)

print(f"✓ {module_id}/{ex_name}: Score={score}, Grade={grade}, +{xp_gained} XP (Gesamt: {p['xp']}), Level {p['level']} – {p['level_title']}")
PYEOF

echo -e "${GREEN}${BOLD}progress.json aktualisiert.${RESET}"
