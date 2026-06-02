#!/usr/bin/env python3
"""Status-Header: XP, Level, Woche, Module-Übersicht"""
import json, sys
try:
    p = json.load(open(sys.argv[1], encoding="utf-8"))
except Exception:
    p = {}
C='\033[0;36m'; G='\033[0;32m'; P='\033[0;35m'; B='\033[1m'; D='\033[2m'; R='\033[0m'
xp    = p.get("xp", 0); lvl = p.get("level", 0)
title = p.get("level_title", "Piscine Newbie")
wxp   = p.get("weekly_xp", 0); wgoal = p.get("weekly_goal_xp", 100)
frac  = max(0, min(1, (xp - lvl*200) / 200)) if lvl < 6 else 1.0
bar   = "█" * int(frac*18) + "░" * (18 - int(frac*18))
wfrac = max(0, min(1, wxp/wgoal)) if wgoal else 0
wbar  = "█" * int(wfrac*18) + "░" * (18 - int(wfrac*18))
badges_n   = len(p.get("badges_total", []))
mods_done  = sum(1 for m in p.get("modules",{}).values() if m.get("status") == "completed")
mods_total = len(p.get("modules",{}))
print(f"{B}{P}╔═══════════════════════════════════════════════════════════╗{R}")
print(f"{B}{P}║{R}  {B}42 LERNTOOL{R}  ·  Piscine                    Rene        {B}{P}║{R}")
print(f"{B}{P}╚═══════════════════════════════════════════════════════════╝{R}")
print(f"  {B}Level {lvl}{R}  {P}{title}{R}   XP {C}{bar}{R} {B}{xp}{R}")
print(f"  Woche {G}{wbar}{R} {wxp}/{wgoal}  Streak {p.get('streak_weeks',0)}W  🏅 {badges_n} Orden  Module {mods_done}/{mods_total}")
