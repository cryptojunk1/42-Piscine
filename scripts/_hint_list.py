#!/usr/bin/env python3
"""Zeigt verfügbare Hinweis-Stufen"""
import json, sys
spec = json.load(open(sys.argv[1], encoding="utf-8"))
name = sys.argv[2]
e    = next((x for x in spec["exercises"] if x["name"] == name), None)
B='\033[1m'; D='\033[2m'; R='\033[0m'
if not e: print("Keine Hints."); sys.exit()
labels = [("1_concept","Stufe 1 – Konzept"),("2_denkanstoß","Stufe 2 – Denkanstoß"),
          ("3_pseudocode","Stufe 3 – Pseudocode"),("4_notausgang","Stufe 4 – Notausgang")]
h = e.get("hints", {})
print(f"\n  {B}Hinweise zu {name}{R} {D}– nur so viel wie nötig!{R}")
for i,(k,lab) in enumerate(labels):
    if k in h: print(f"   {B}{i+1}{R}) {lab}")
print(f"   {D}0) Zurück{R}")
