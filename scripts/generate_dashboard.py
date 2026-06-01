#!/usr/bin/env python3
"""42 Lerntool -- Dashboard Generator. Usage: python3 scripts/generate_dashboard.py [--open]"""
import json, os, subprocess, webbrowser, argparse

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
TOOL_ROOT  = os.path.dirname(SCRIPT_DIR)
PROGRESS   = os.path.join(os.path.dirname(TOOL_ROOT), "progress.json")
EXERCISES  = os.path.join(TOOL_ROOT, "subjects", "c00_exercises.json")
TEMPLATE   = os.path.join(SCRIPT_DIR, "dashboard_template.html")
OUT_HTML   = os.path.join(TOOL_ROOT, "dashboard.html")

parser = argparse.ArgumentParser()
parser.add_argument("--open", action="store_true")
args = parser.parse_args()

with open(PROGRESS,  "r", encoding="utf-8") as f: p       = json.load(f)
with open(EXERCISES, "r", encoding="utf-8") as f: ex_spec = json.load(f)
with open(TEMPLATE,  "r", encoding="utf-8") as f: tmpl    = f.read()

# --- Git stats ---
git_commits, git_last, git_remote = 0, "noch keine commits", ""
try:
    d = TOOL_ROOT  # Repo liegt jetzt im Tool-Ordner
    out = subprocess.check_output(["git","-C",d,"log","--oneline"], stderr=subprocess.DEVNULL).decode()
    lns = [l for l in out.strip().splitlines() if l]
    git_commits = len(lns)
    git_last    = lns[0].split(" ",1)[1] if lns else "noch keine commits"
    rem = subprocess.check_output(["git","-C",d,"remote","get-url","origin"], stderr=subprocess.DEVNULL).decode().strip()
    if "github.com" in rem:
        rp = rem.replace("https://github.com/","").replace("git@github.com:","").rstrip(".git")
        git_remote = "https://github.com/" + rp
except Exception:
    pass

# --- Progress ---
xp          = p.get("xp",0);          level       = p.get("level",0)
title       = p.get("level_title","Piscine Newbie")
weekly_xp   = p.get("weekly_xp",0);   weekly_goal = p.get("weekly_goal_xp",100)
streak      = p.get("streak_weeks",0); badges      = p.get("badges_total",[])
updated     = p.get("updated","")
next_xp     = [200,500,900,1400,2000,9999][min(level,5)]
prev_xp     = [0,200,500,900,1400,2000][min(level,5)]
xp_pct      = int(100*(xp-prev_xp)/max(next_xp-prev_xp,1))
week_pct    = min(100, int(100*weekly_xp/max(weekly_goal,1)))
c00         = p["modules"]["C00"]
ep          = c00["exercises"]
done_count  = sum(1 for e in ep.values() if e.get("done"))
total_count = len(ep)
mod_pct     = int(100*done_count/total_count)

# --- Merge exercises ---
ex_list = []
for s in ex_spec["exercises"]:
    nm = s["name"]; pr = ep.get(nm,{})
    cp = os.path.join(TOOL_ROOT,"peer",nm,nm+".c")
    ex_list.append({
        "id":s["id"],"name":nm,
        "desc_en":s.get("description",""),"desc_de":s.get("description_de",""),
        "why":s.get("why_it_matters",""),"example":s.get("example_output",""),
        "prototype":s.get("prototype",""),"allowed":s.get("allowed_functions",[]),
        "links":s.get("learning_links",[]),"xp":s.get("xp_reward",0),
        "hints":s.get("hints",{}),"done":pr.get("done",False),
        "score":pr.get("best_score"),"grade":pr.get("grade"),
        "attempts":pr.get("attempts",0),"hint_level":pr.get("hint_level",0),
        "has_file":os.path.exists(cp)
    })

def badge_label(bid):
    if "gold"   in bid: return bid.replace("C00_","").replace("_gold","")   + " - Gold"
    if "silver" in bid: return bid.replace("C00_","").replace("_silver","") + " - Silber"
    if "bronze" in bid: return bid.replace("C00_","").replace("_bronze","") + " - Bronze"
    if "exam"   in bid: return "Exam bestanden"
    return bid

badges_data = [{"id":b,"label":badge_label(b)} for b in badges]
git_last_s  = git_last[:40]+("..." if len(git_last)>40 else "")
git_ri      = ("GitHub: "+git_remote) if git_remote else "Kein Remote. git_setup.sh ausfuehren."
git_lb      = ('<a href="'+git_remote+'" target="_blank"><button class="git-btn">GitHub oeffnen</button></a>') if git_remote else ""

# --- Simple str.replace templating ---
replacements = {
    "__LEVEL__":         str(level),
    "__TITLE__":         title,
    "__XP__":            str(xp),
    "__NEXT_LEVEL__":    str(level+1),
    "__XP_NEEDED__":     str(max(0,next_xp-xp)),
    "__WEEKLY_XP__":     str(weekly_xp),
    "__WEEKLY_GOAL__":   str(weekly_goal),
    "__STREAK__":        str(streak),
    "__DONE_COUNT__":    str(done_count),
    "__TOTAL_COUNT__":   str(total_count),
    "__MOD_PCT__":       str(mod_pct),
    "__GIT_COMMITS__":   str(git_commits),
    "__GIT_LAST__":      git_last,
    "__GIT_LAST_SHORT__":git_last_s,
    "__GIT_REMOTE_INFO__":git_ri,
    "__GIT_LINK_BTN__":  git_lb,
    "__UPDATED__":       updated,
    "__XP_PCT__":        str(xp_pct),
    "__WEEK_PCT__":      str(week_pct),
    "__EX_JSON__":       json.dumps(ex_list, ensure_ascii=False),
    "__BADGES_JSON__":   json.dumps(badges_data, ensure_ascii=False),
}

html = tmpl
for k, v in replacements.items():
    html = html.replace(k, v)

with open(OUT_HTML,"w",encoding="utf-8") as f:
    f.write(html)
print(f"Dashboard geschrieben: {OUT_HTML}")
if args.open:
    webbrowser.open("file://"+OUT_HTML.replace("\\","/"))
