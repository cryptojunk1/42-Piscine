#!/usr/bin/env python3
"""Zeigt eine Hinweis-Stufe + schreibt hint_level in progress.json"""
import json, sys
spec = json.load(open(sys.argv[1], encoding="utf-8"))
name = sys.argv[2]; hl = int(sys.argv[3])
prog_path = sys.argv[4]; module = sys.argv[5]
e    = next((x for x in spec["exercises"] if x["name"] == name), None)
keys = ["1_concept","2_denkanstoß","3_pseudocode","4_notausgang"]
C='\033[0;36m'; R='\033[0m'
txt  = e.get("hints",{}).get(keys[hl-1],"(kein Text)") if e else "(nicht gefunden)"
print(f"\n{C}{'─'*60}{R}\n{txt}\n{C}{'─'*60}{R}")
try:
    p   = json.load(open(prog_path, encoding="utf-8"))
    ent = p["modules"].get(module,{}).get("exercises",{}).get(name)
    if ent and hl > ent.get("hint_level",0):
        ent["hint_level"] = hl
        json.dump(p, open(prog_path,"w",encoding="utf-8"), indent=2, ensure_ascii=False)
except Exception: pass
