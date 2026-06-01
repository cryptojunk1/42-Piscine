#!/bin/bash
# =============================================================================
# 42 Lerntool – go.sh  (der "42"-Launcher)
# EIN Befehl für alles: Status, Übung wählen, anlegen, prüfen, Hinweise, Exam.
# Aufruf:  42        (nach Einrichtung via scripts/install.sh)
#     oder:  bash go.sh
# =============================================================================

set -uo pipefail

TOOL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS="$TOOL_ROOT/scripts"
PEER="$TOOL_ROOT/peer"
SUBJECTS="$TOOL_ROOT/subjects/c00_exercises.json"
PROGRESS="$(dirname "$TOOL_ROOT")/progress.json"
# Repo liegt jetzt IM Tool-Ordner (nach migrate_repo.sh)
REPO_ROOT="$TOOL_ROOT"
export PATH="$PATH:$HOME/.local/bin"

# Farben
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
PURPLE='\033[0;35m'; BLUE='\033[0;34m'; BOLD='\033[1m'; DIM='\033[2m'; RESET='\033[0m'

# Reihenfolge der Übungen
EXS=(ft_putchar ft_print_alphabet ft_print_reverse_alphabet ft_print_numbers \
     ft_is_negative ft_print_comb ft_print_comb2 ft_putnbr ft_print_combn)

# ─── Editor erkennen ─────────────────────────────────────────────────────────
pick_editor() {
  if [ -n "${EDITOR:-}" ]; then echo "$EDITOR"; return; fi
  if command -v code >/dev/null 2>&1; then echo "code"; return; fi
  if command -v nano >/dev/null 2>&1; then echo "nano"; return; fi
  echo "vi"
}

launch_peer() {
  local ctx="${1:-$PEER}"
  if ! command -v claude >/dev/null 2>&1; then
    echo -e "\n${YELLOW}Claude Code ist in WSL nicht installiert.${RESET}"
    echo -e "Installation: ${CYAN}https://docs.claude.com/claude-code${RESET}"
    echo -e "Test danach: ${CYAN}claude --version${RESET}"
    read -rp "  [Enter] zurück ..." _; return
  fi
  echo -e "\n${PURPLE}${BOLD}Dein Peer (Claude Code) startet ...${RESET}"
  echo -e "${DIM}Er gibt Hinweise nur stufenweise. Sag \"Notausgang\" für die volle Lösung. Beenden: /exit${RESET}\n"
  ( cd "$ctx" && claude )
}

open_in_browser() {
  local f="$1"
  if command -v explorer.exe >/dev/null 2>&1; then ( cd "$(dirname "$f")" && explorer.exe "$(basename "$f")" >/dev/null 2>&1 & )
  elif command -v wslview   >/dev/null 2>&1; then wslview "$f" >/dev/null 2>&1 &
  elif command -v xdg-open  >/dev/null 2>&1; then xdg-open "$f" >/dev/null 2>&1 &
  else echo -e "${YELLOW}Öffne manuell im Browser:${RESET} $f"; fi
}

# ─── Status-Kopf rendern ─────────────────────────────────────────────────────
print_header() {
  clear
  python3 - "$PROGRESS" "$SUBJECTS" << 'PY'
import json, sys
prog_path, subj_path = sys.argv[1], sys.argv[2]
try:
    p = json.load(open(prog_path, encoding="utf-8"))
except Exception:
    p = {}
C='\033[0;36m'; G='\033[0;32m'; Y='\033[1;33m'; P='\033[0;35m'; B='\033[1m'; D='\033[2m'; R='\033[0m'
xp   = p.get("xp",0); lvl = p.get("level",0); title = p.get("level_title","Piscine Newbie")
wxp  = p.get("weekly_xp",0); wgoal = p.get("weekly_goal_xp",100)
strk = p.get("streak_weeks",0); badges = p.get("badges_total",[])
exs  = p.get("modules",{}).get("C00",{}).get("exercises",{})
done = sum(1 for e in exs.values() if e.get("done"))
total= len(exs) if exs else 9
# XP-Balken zum nächsten Level (alle 200 XP grob)
nxt = (lvl+1)*200
into = xp - lvl*200
frac = max(0,min(1, into/200)) if nxt else 0
bar = "█"*int(frac*18) + "░"*(18-int(frac*18))
wfrac= max(0,min(1, wxp/wgoal)) if wgoal else 0
wbar = "█"*int(wfrac*18) + "░"*(18-int(wfrac*18))
print(f"{B}{P}╔══════════════════════════════════════════════════════════╗{R}")
print(f"{B}{P}║{R}  {B}42 LERNTOOL{R}  ·  Piscine C00            Rene        {B}{P}║{R}")
print(f"{B}{P}╚══════════════════════════════════════════════════════════╝{R}")
print(f"  {B}Level {lvl}{R} {D}·{R} {P}{title}{R}")
print(f"  XP   {C}{bar}{R} {B}{xp}{R}  {D}(nächstes Level bei {nxt}){R}")
print(f"  Woche{G}{wbar}{R} {wxp}/{wgoal} XP {D}·{R} Streak {strk} Wochen {D}(sanftes Ziel){R}")
print(f"  C00  {done}/{total} Übungen {D}·{R} 🏅 {len(badges)} Orden")
PY
}

# ─── Übungsliste rendern ─────────────────────────────────────────────────────
print_exlist() {
  python3 - "$PROGRESS" "$SUBJECTS" "$PEER" << 'PY'
import json, sys, os
prog_path, subj_path, peer = sys.argv[1], sys.argv[2], sys.argv[3]
p = json.load(open(prog_path, encoding="utf-8"))
spec = json.load(open(subj_path, encoding="utf-8"))
exs = p.get("modules",{}).get("C00",{}).get("exercises",{})
G='\033[0;32m'; Y='\033[1;33m'; C='\033[0;36m'; D='\033[2m'; B='\033[1m'; R='\033[0m'
order=[e["name"] for e in spec["exercises"]]
print(f"\n  {B}Übungen{R}  {D}(Nummer eingeben zum Öffnen){R}\n")
for i,name in enumerate(order, start=1):
    e = exs.get(name,{})
    grade = e.get("grade"); score = e.get("best_score")
    has_file = os.path.isfile(os.path.join(peer,name,name+".c"))
    if e.get("done"):
        icon = {"gold":"🥇","silver":"🥈","bronze":"🥉"}.get(grade,"✅")
        st = f"{G}bestanden {score}/100{R}"
    elif has_file:
        icon = "✏️ "; st = f"{Y}in Arbeit{R}"
    else:
        icon = "·"; st = f"{D}offen{R}"
    xp = next((x.get("xp_reward",0) for x in spec["exercises"] if x["name"]==name),0)
    print(f"   {B}{i}){R} {icon} {name:<28} {st}  {D}+{xp} XP{R}")
PY
}

# ─── Hinweise einer Übung anzeigen (gestuft) ─────────────────────────────────
show_hints() {
  local ex="$1"
  python3 - "$SUBJECTS" "$ex" << 'PY'
import json, sys
spec = json.load(open(sys.argv[1], encoding="utf-8"))
ex = sys.argv[2]
e = next((x for x in spec["exercises"] if x["name"]==ex), None)
C='\033[0;36m'; Y='\033[1;33m'; B='\033[1m'; D='\033[2m'; R='\033[0m'
if not e: print("Keine Hinweise."); sys.exit()
labels=[("1_concept","Stufe 1 – Konzept"),("2_denkanstoß","Stufe 2 – Denkanstoß"),
        ("3_pseudocode","Stufe 3 – Pseudocode"),("4_notausgang","Stufe 4 – Notausgang (Lösung)")]
h=e.get("hints",{})
print(f"\n  {B}Hinweise zu {ex}{R} {D}– nur so viel aufdecken wie nötig!{R}")
for i,(k,lab) in enumerate(labels):
    if k in h: print(f"   {B}{i+1}{R}) {lab}")
print(f"   {D}0) Zurück{R}")
PY
  echo ""
  read -rp "  Welche Stufe aufdecken? [0-4]: " hl
  [[ "$hl" =~ ^[1-4]$ ]] || return
  python3 - "$SUBJECTS" "$ex" "$hl" "$PROGRESS" << 'PY'
import json, sys
spec = json.load(open(sys.argv[1], encoding="utf-8"))
ex, hl, prog_path = sys.argv[2], int(sys.argv[3]), sys.argv[4]
e = next((x for x in spec["exercises"] if x["name"]==ex), None)
keys=["1_concept","2_denkanstoß","3_pseudocode","4_notausgang"]
C='\033[0;36m'; Y='\033[1;33m'; B='\033[1m'; R='\033[0m'
txt = e.get("hints",{}).get(keys[hl-1],"(kein Text)")
print(f"\n{C}{'─'*60}{R}")
print(txt)
print(f"{C}{'─'*60}{R}")
# hint_level in progress.json hochsetzen (für Dashboard-Locks)
try:
    p=json.load(open(prog_path,encoding="utf-8"))
    ent=p["modules"]["C00"]["exercises"].get(ex)
    if ent and hl>ent.get("hint_level",0):
        ent["hint_level"]=hl
        json.dump(p,open(prog_path,"w",encoding="utf-8"),indent=2,ensure_ascii=False)
except Exception: pass
PY
  echo ""
  read -rp "  [Enter] zum Weiterlernen ..." _
}

# ─── Eine Übung bearbeiten ───────────────────────────────────────────────────
exercise_menu() {
  local ex="$1"
  local cfile="$PEER/$ex/$ex.c"
  # Datei anlegen falls noch nicht da
  if [ ! -f "$cfile" ]; then
    echo -e "\n${CYAN}Lege $ex an ...${RESET}"
    bash "$SCRIPTS/new.sh" "$ex" >/dev/null
    echo -e "${GREEN}✓ Datei + 42-Header erstellt${RESET}"
  fi
  while true; do
    print_header
    echo -e "\n  ${BOLD}▶ $ex${RESET}   ${DIM}$cfile${RESET}\n"
    echo -e "   ${BOLD}e${RESET}) Editor öffnen   ($(pick_editor))"
    echo -e "   ${BOLD}c${RESET}) Prüfen          (Norminette + Kompilieren + Tests, trägt Score automatisch ein)"
    echo -e "   ${BOLD}h${RESET}) Hinweise        (gestuft – schnelle Standard-Hinweise)"
    echo -e "   ${BOLD}f${RESET}) Peer fragen     (Claude Code – echtes Gespräch zur Übung)"
    echo -e "   ${BOLD}p${RESET}) Aufgabe lesen   (Subject im Terminal)"
    echo -e "   ${BOLD}z${RESET}) Zurück zum Hauptmenü"
    echo ""
    read -rp "  > " act
    case "$act" in
      e|E)
        local ed; ed="$(pick_editor)"
        echo -e "${DIM}Öffne $cfile in $ed ...${RESET}"
        if [ "$ed" = "code" ]; then "$ed" "$cfile" >/dev/null 2>&1 & else "$ed" "$cfile"; fi
        ;;
      c|C)
        echo ""
        bash "$SCRIPTS/check.sh" "$ex" || true
        echo ""
        read -rp "  [Enter] zurück ..." _
        ;;
      h|H) show_hints "$ex" ;;
      f|F) launch_peer "$PEER/$ex" ;;
      p|P) show_subject "$ex" ;;
      z|Z|q|Q) return ;;
      *) ;;
    esac
  done
}

show_subject() {
  local ex="$1"
  python3 - "$SUBJECTS" "$ex" << 'PY'
import json,sys
spec=json.load(open(sys.argv[1],encoding="utf-8"))
e=next((x for x in spec["exercises"] if x["name"]==sys.argv[2]),None)
B='\033[1m'; C='\033[0;36m'; G='\033[0;32m'; D='\033[2m'; R='\033[0m'
if not e: print("nicht gefunden"); sys.exit()
print(f"\n{B}{e['name']}{R}  {D}(+{e.get('xp_reward',0)} XP){R}")
print(f"\n{B}Aufgabe:{R}\n  "+e.get("description_de",e.get("description",""))[:600])
if e.get("why_it_matters"): print(f"\n{B}Warum wichtig:{R}\n  {e['why_it_matters'][:400]}")
print(f"\n{B}Prototyp:{R}  {C}{e.get('prototype','')}{R}")
print(f"{B}Erlaubt:{R}   {', '.join(e.get('allowed_functions',[]))}")
if e.get("example_output"): print(f"\n{B}Erwartete Ausgabe:{R}\n{G}{e['example_output']}{R}")
for l in e.get("learning_links",[]):
    print(f"  🔗 {l.get('title','')}: {l.get('url','')}")
PY
  echo ""
  read -rp "  [Enter] zurück ..." _
}

# ─── Hauptmenü ───────────────────────────────────────────────────────────────
main_menu() {
  while true; do
    print_header
    print_exlist
    echo -e "\n  ${BOLD}Aktionen${RESET}"
    echo -e "   ${BOLD}1-9${RESET}) Übung öffnen        ${BOLD}d${RESET}) Dashboard   ${BOLD}t${RESET}) Trophäenschrank"
    echo -e "   ${BOLD}p${RESET}) Peer fragen         ${BOLD}e${RESET}) Exam starten ${BOLD}g${RESET}) Git-Status  ${BOLD}q${RESET}) Beenden"
    echo ""
    read -rp "  > " choice
    case "$choice" in
      [1-9])
        idx=$((choice-1))
        if [ "$idx" -lt "${#EXS[@]}" ]; then exercise_menu "${EXS[$idx]}"; fi
        ;;
      d|D) open_in_browser "$TOOL_ROOT/dashboard.html"; echo -e "${GREEN}Dashboard im Browser geöffnet.${RESET}"; sleep 1 ;;
      p|P) launch_peer ;;
      t|T) clear; bash "$SCRIPTS/trophy.sh"; echo ""; read -rp "  [Enter] zurück ..." _ ;;
      e|E)
        clear
        echo -e "${YELLOW}${BOLD}Achtung:${RESET} Im Exam gibt es KEINEN Tutor und KEINE Hinweise."
        read -rp "  Exam wirklich starten? [j/N]: " ok
        [[ "$ok" =~ ^[jJyY]$ ]] && bash "$TOOL_ROOT/exam/exam.sh"
        echo ""; read -rp "  [Enter] zurück ..." _
        ;;
      g|G)
        clear
        echo -e "${BOLD}Git-Status:${RESET}\n"
        ( cd "$REPO_ROOT" && git status --short && echo "" && git log --oneline -5 2>/dev/null )
        echo -e "\n${CYAN}Commit (selbst tippen – Git lernt man durch Tun):${RESET}"
        echo -e "  cd \"$REPO_ROOT\" && git add -A && git commit -m \"...\" && git push"
        echo ""; read -rp "  [Enter] zurück ..." _
        ;;
      q|Q) clear; echo -e "${PURPLE}Bis bald – dranbleiben! 🚀${RESET}\n"; exit 0 ;;
      *) ;;
    esac
  done
}

# Vorbedingungen
if [ ! -f "$PROGRESS" ]; then echo -e "${RED}progress.json nicht gefunden: $PROGRESS${RESET}"; exit 1; fi
command -v python3 >/dev/null 2>&1 || { echo -e "${RED}python3 wird benötigt.${RESET}"; exit 1; }

main_menu
