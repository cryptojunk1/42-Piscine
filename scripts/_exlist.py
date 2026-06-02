#!/usr/bin/env python3
"""Übungsliste eines Moduls"""
import json, os, sys
p      = json.load(open(sys.argv[1], encoding="utf-8"))
spec   = json.load(open(sys.argv[2], encoding="utf-8"))
peer   = sys.argv[3]; module = sys.argv[4]
exs    = p.get("modules", {}).get(module, {}).get("exercises", {})
G='\033[0;32m'; Y='\033[1;33m'; D='\033[2m'; B='\033[1m'; R='\033[0m'
print(f"\n  {B}Übungen – {module}{R}  {D}(Nummer eingeben){R}\n")
for i, sx in enumerate(spec["exercises"], start=1):
    name   = sx["name"]
    ex     = exs.get(name, {})
    ex_dir = sx.get("directory","").rstrip("/")
    files  = sx.get("files", [])
    has    = any(os.path.isfile(os.path.join(peer, ex_dir, f)) for f in files)
    if ex.get("done"):
        grade = ex.get("grade","")
        icon  = {"gold":"🥇","silver":"🥈","bronze":"🥉"}.get(grade,"✅")
        st    = f"{G}bestanden {ex.get('best_score')}/100{R}"
    elif has:
        icon = "✏️ "; st = f"{Y}in Arbeit{R}"
    else:
        icon = "·"; st = f"{D}offen{R}"
    xp = sx.get("xp_reward", 0)
    print(f"   {B}{i}){R} {icon} {sx['id']} {name:<28} {st}  {D}+{xp} XP{R}")
