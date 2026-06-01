#!/bin/bash
# =============================================================================
# 42 Lerntool – trophy.sh
# Zeigt den Trophäenschrank: Orden, XP, Level, Streak, Status
# Usage: bash trophy.sh
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOL_ROOT="$(dirname "$SCRIPT_DIR")"
PROGRESS="$(dirname "$TOOL_ROOT")/progress.json"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BLUE='\033[0;34m'; MAGENTA='\033[0;35m'
BOLD='\033[1m'; DIM='\033[2m'; RESET='\033[0m'

if [ ! -f "$PROGRESS" ]; then
  echo -e "${RED}progress.json nicht gefunden: $PROGRESS${RESET}"; exit 1
fi

export PROGRESS_PATH="$PROGRESS"
python3 << 'PYEOF'
import json, sys, os

progress_path = os.environ.get('PROGRESS_PATH', '')

try:
    with open(progress_path, 'r') as f:
        p = json.load(f)
except Exception as e:
    print(f"Fehler beim Lesen von progress.json: {e}")
    sys.exit(1)

RESET = '\033[0m'; BOLD = '\033[1m'; DIM = '\033[2m'
RED = '\033[0;31m'; GREEN = '\033[0;32m'; YELLOW = '\033[1;33m'
CYAN = '\033[0;36m'; BLUE = '\033[0;34m'; MAGENTA = '\033[0;35m'

def bar(current, total, width=20):
    filled = int(width * current / max(total, 1))
    return f"[{'█' * filled}{'░' * (width - filled)}]"

# Header
print(f"\n{BOLD}{BLUE}")
print("  ╔══════════════════════════════════════════════════════╗")
print("  ║          🏆  TROPHÄENSCHRANK – 42 LERNTOOL  🏆       ║")
print(f"  ╚══════════════════════════════════════════════════════╝{RESET}")

# User & Level
xp = p.get('xp', 0)
level = p.get('level', 0)
title = p.get('level_title', 'Piscine Newbie')
next_level_xp = [200, 500, 900, 1400, 2000, 9999]
next_xp = next_level_xp[min(level, len(next_level_xp)-1)]
prev_xp = [0, 200, 500, 900, 1400, 2000][min(level, 5)]
level_progress = xp - prev_xp
level_needed = next_xp - prev_xp

print(f"\n  {BOLD}👤 {p.get('user', 'Rene')}{RESET}  |  Level {level} – {CYAN}{title}{RESET}")
print(f"  {BOLD}XP:{RESET} {xp}  {bar(level_progress, level_needed)}  → Level {level+1} in {max(0, next_xp - xp)} XP")

# Weekly Goal
weekly = p.get('weekly_xp', 0)
weekly_goal = p.get('weekly_goal_xp', 100)
week = p.get('current_week', '?')
goal_icon = "✅" if weekly >= weekly_goal else "🎯"
print(f"  {BOLD}Wochenziel:{RESET} {goal_icon} {weekly}/{weekly_goal} XP  [{week}]  {bar(weekly, weekly_goal, 15)}")

# Streak
streak = p.get('streak_weeks', 0)
if streak >= 4:
    streak_icon = "🔥🔥🔥"
elif streak >= 2:
    streak_icon = "🔥🔥"
elif streak >= 1:
    streak_icon = "🔥"
else:
    streak_icon = "💤"
print(f"  {BOLD}Streak:{RESET} {streak_icon} {streak} Wochen in Folge")

# Module-Übersicht
print(f"\n  {BOLD}{MAGENTA}══ MODULE ══{RESET}")
for mod_name, mod in p.get('modules', {}).items():
    status = mod.get('status', 'not_started')
    exam = mod.get('exam_score')
    exs = mod.get('exercises', {})
    done_count = sum(1 for e in exs.values() if e.get('done'))
    total_count = len(exs)

    status_icon = {"completed": "✅", "in_progress": "🔄", "not_started": "🔒"}.get(status, "?")
    exam_str = f"Exam: {exam}/100" if exam is not None else "Exam: –"
    print(f"  {status_icon} {BOLD}{mod_name}{RESET}  {bar(done_count, total_count, 10)}  {done_count}/{total_count} Übungen  |  {exam_str}")

    # Übungs-Detail
    for ex_name, ex in exs.items():
        done = ex.get('done', False)
        score = ex.get('best_score')
        grade = ex.get('grade')
        hints = ex.get('hint_level', 0)
        attempts = ex.get('attempts', 0)

        if done:
            grade_icons = {"gold": "🥇", "silver": "🥈", "bronze": "🥉"}
            g_icon = grade_icons.get(grade, "✓")
            score_str = f"{score}/100" if score else "–"
            print(f"    {g_icon} {ex_name:<30} {score_str}")
        elif attempts > 0:
            print(f"    ⏳ {ex_name:<30} {DIM}in Bearbeitung (Hint {hints}/4){RESET}")
        else:
            print(f"    {DIM}○  {ex_name:<30} noch nicht begonnen{RESET}")

# Badges
all_badges = p.get('badges_total', [])
print(f"\n  {BOLD}{YELLOW}══ ORDEN & BADGES ══{RESET}")
if not all_badges:
    print(f"  {DIM}Noch keine Orden – lern weiter! Erster wartet auf ft_putchar 🎯{RESET}")
else:
    badge_display = {
        "gold": ("🥇", YELLOW + BOLD),
        "silver": ("🥈", CYAN),
        "bronze": ("🥉", ""),
        "exam_passed": ("🎫", GREEN + BOLD),
    }
    for badge in all_badges:
        parts = badge.split('_')
        if 'exam' in badge:
            icon, color = "🎫", GREEN + BOLD
            label = "Exam Bestanden"
        elif 'gold' in badge:
            icon, color = "🥇", YELLOW + BOLD
            label = badge.replace('C00_', '').replace('_gold', '') + " [Gold]"
        elif 'silver' in badge:
            icon, color = "🥈", CYAN
            label = badge.replace('C00_', '').replace('_silver', '') + " [Silber]"
        elif 'bronze' in badge:
            icon, color = "🥉", ""
            label = badge.replace('C00_', '').replace('_bronze', '') + " [Bronze]"
        else:
            icon, color = "🏅", ""
            label = badge
        print(f"  {icon} {color}{label}{RESET}")

# Zertifikate
certs = [m.get('certificate') for m in p.get('modules', {}).values() if m.get('certificate')]
if certs:
    print(f"\n  {BOLD}{GREEN}══ ZERTIFIKATE ══{RESET}")
    for cert in certs:
        print(f"  📜 {cert}")

print(f"\n  {DIM}Stand: {p.get('updated', '?')}{RESET}")
print()
PYEOF
