#!/usr/bin/env python3
"""Aufgaben-Beschreibung ausgeben"""
import json, sys
spec = json.load(open(sys.argv[1], encoding="utf-8"))
e    = next((x for x in spec["exercises"] if x["name"] == sys.argv[2]), None)
B='\033[1m'; C='\033[0;36m'; G='\033[0;32m'; D='\033[2m'; R='\033[0m'
if not e: print("nicht gefunden"); sys.exit()
print(f"\n{B}{e['id']} – {e['name']}{R}  {D}+{e.get('xp_reward',0)} XP{R}")
desc = e.get("description_de") or e.get("description","")
print(f"\n{B}Aufgabe:{R}\n  {desc[:700]}")
if e.get("why_it_matters"):    print(f"\n{B}Warum:{R}\n  {e['why_it_matters'][:400]}")
if e.get("prototype"):          print(f"\n{B}Prototyp:{R}  {C}{e['prototype']}{R}")
if e.get("allowed_functions"):  print(f"{B}Erlaubt:{R}   {', '.join(e['allowed_functions'])}")
if e.get("example_output"):     print(f"\n{B}Beispiel:{R}\n{G}{e['example_output']}{R}")
for l in e.get("learning_links", []):
    print(f"  🔗 {l.get('title','')}: {l.get('url','')}")
