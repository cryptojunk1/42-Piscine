#!/usr/bin/env python3
"""Kleiner Status-Block für eine Übung"""
import json, sys
p      = json.load(open(sys.argv[1], encoding="utf-8"))
module = sys.argv[2]; name = sys.argv[3]
ex     = p.get("modules",{}).get(module,{}).get("exercises",{}).get(name,{})
B='\033[1m'; G='\033[0;32m'; Y='\033[1;33m'; D='\033[2m'; R='\033[0m'
score = ex.get("best_score"); done = ex.get("done", False)
att   = ex.get("attempts", 0)
if done:   st = f"{G}✅ bestanden ({score}/100), Versuche: {att}{R}"
elif att:  st = f"{Y}in Arbeit – bisher {score}/100, {att} Versuch(e){R}"
else:       st = f"{D}noch nicht gestartet{R}"
print(f"  Status: {st}")
