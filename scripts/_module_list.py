#!/usr/bin/env python3
"""Modul-Liste aus curriculum.json"""
import json, os, sys
p    = json.load(open(sys.argv[1], encoding="utf-8"))
cur  = json.load(open(sys.argv[2], encoding="utf-8"))
subj = sys.argv[3]
G='\033[0;32m'; Y='\033[1;33m'; D='\033[2m'; B='\033[1m'; R='\033[0m'
print(f"\n  {B}Piscine – Module{R}  {D}(Nummer wählen){R}\n")
idx = 1
for phase in cur["phases"]:
    if phase["id"] != "piscine":
        continue
    for m in phase["path"]:
        mid    = m["id"]
        json_f = os.path.join(subj, mid.lower() + "_exercises.json")
        if not os.path.isfile(json_f):
            continue
        mod_data = p.get("modules", {}).get(mid, {})
        status   = mod_data.get("status", "not_started")
        exs      = mod_data.get("exercises", {})
        done     = sum(1 for e in exs.values() if e.get("done"))
        total    = len(exs)
        if   status == "completed":   icon = G+"✅"+R; st = G+"fertig"+R
        elif status == "in_progress": icon = Y+"✏️ "+R; st = Y+"läuft"+R
        else:                          icon = D+"·"+R;  st = D+"offen"+R
        print(f"   {B}{idx}){R} {icon} {m['label']:<12}  {done}/{total} Übungen  {st}")
        idx += 1
