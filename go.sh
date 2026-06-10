#!/bin/bash
# =============================================================================
# 42 Lerntool – go.sh  (Multi-Modul-Launcher)
# Aufruf: 42  (nach install.sh) oder bash go.sh
# =============================================================================

set -uo pipefail

TOOL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS="$TOOL_ROOT/scripts"
PEER="$TOOL_ROOT/peer"
SUBJECTS="$TOOL_ROOT/subjects"
CURRICULUM="$SUBJECTS/curriculum.json"
PROGRESS="$(dirname "$TOOL_ROOT")/progress.json"
REPO_ROOT="$TOOL_ROOT"
export PATH="$PATH:$HOME/.local/bin"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
PURPLE='\033[0;35m'; BOLD='\033[1m'; DIM='\033[2m'; RESET='\033[0m'

[ -f "$PROGRESS" ]   || { echo -e "${RED}progress.json nicht gefunden: $PROGRESS${RESET}"; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo -e "${RED}python3 benötigt.${RESET}"; exit 1; }
[ -f "$CURRICULUM" ] || { echo -e "${RED}curriculum.json nicht gefunden${RESET}"; exit 1; }

pick_editor() {
  [ -n "${EDITOR:-}" ] && echo "$EDITOR" && return
  command -v code >/dev/null 2>&1 && echo "code" && return
  command -v nano >/dev/null 2>&1 && echo "nano" && return
  echo "vi"
}

launch_peer() {
  local ctx="${1:-$PEER}"
  if ! command -v claude >/dev/null 2>&1; then
    echo -e "\n${YELLOW}Claude Code nicht installiert.${RESET}"
    echo -e "  ${CYAN}https://docs.claude.com/claude-code${RESET}"
    read -rp "  [Enter] ..." _; return
  fi
  echo -e "\n${PURPLE}${BOLD}Peer startet ...${RESET}"
  echo -e "${DIM}Gestufte Hinweise. \"Notausgang\" = Lösung. /exit = Ende.${RESET}\n"
  ( cd "$ctx" && claude )
}

open_in_browser() {
  local f="$1"
  command -v explorer.exe >/dev/null 2>&1 && { ( cd "$(dirname "$f")" && explorer.exe "$(basename "$f")" >/dev/null 2>&1 & ); return; }
  command -v wslview      >/dev/null 2>&1 && { wslview "$f" >/dev/null 2>&1 & return; }
  command -v xdg-open     >/dev/null 2>&1 && { xdg-open "$f" >/dev/null 2>&1 & return; }
  echo -e "${YELLOW}Öffne manuell:${RESET} $f"
}

# ── Globaler Header ───────────────────────────────────────────────────────────
print_global_header() {
  clear
  python3 "$SCRIPTS/_header.py" "$PROGRESS" 2>/dev/null || true
}

# ── Module aus curriculum.json ────────────────────────────────────────────────
get_n_modules() {
  python3 -c "
import json, os
cur = json.load(open('$CURRICULUM', encoding='utf-8'))
n = sum(1 for ph in cur['phases'] if ph['id']=='piscine'
        for m in ph['path']
        if os.path.isfile(os.path.join('$SUBJECTS', m['id'].lower()+'_exercises.json')))
print(n)
"
}

resolve_module_by_index() {
  python3 -c "
import json, os, sys
cur = json.load(open('$CURRICULUM', encoding='utf-8'))
want, idx = int('$1'), 1
for ph in cur['phases']:
    if ph['id'] != 'piscine': continue
    for m in ph['path']:
        if os.path.isfile(os.path.join('$SUBJECTS', m['id'].lower()+'_exercises.json')):
            if idx == want: print(m['id']); sys.exit(0)
            idx += 1
sys.exit(1)
"
}

print_module_list() {
  python3 "$SCRIPTS/_module_list.py" "$PROGRESS" "$CURRICULUM" "$SUBJECTS" 2>/dev/null || true
}

# ── Übungsliste ───────────────────────────────────────────────────────────────
print_exlist() {
  local module="$1" mlow
  mlow=$(echo "$module" | tr '[:upper:]' '[:lower:]')
  python3 "$SCRIPTS/_exlist.py" "$PROGRESS" "$SUBJECTS/${mlow}_exercises.json" "$PEER/$module" "$module" 2>/dev/null || true
}

# ── Hinweise ──────────────────────────────────────────────────────────────────
show_hints() {
  local module="$1" ex_name="$2" mlow
  mlow=$(echo "$module" | tr '[:upper:]' '[:lower:]')
  local jf="$SUBJECTS/${mlow}_exercises.json"
  python3 "$SCRIPTS/_hint_list.py" "$jf" "$ex_name" 2>/dev/null
  echo ""
  read -rp "  Welche Stufe? [0-4]: " hl
  [[ "$hl" =~ ^[1-4]$ ]] || return
  python3 "$SCRIPTS/_hint_show.py" "$jf" "$ex_name" "$hl" "$PROGRESS" "$module" 2>/dev/null
  echo ""; read -rp "  [Enter] weiter ..." _
}

# ── Aufgabe lesen ─────────────────────────────────────────────────────────────
show_subject() {
  local module="$1" ex_name="$2" mlow
  mlow=$(echo "$module" | tr '[:upper:]' '[:lower:]')
  python3 "$SCRIPTS/_subject.py" "$SUBJECTS/${mlow}_exercises.json" "$ex_name" 2>/dev/null
  echo ""; read -rp "  [Enter] zurück ..." _
}

# ── Übungsmenü ────────────────────────────────────────────────────────────────
exercise_menu() {
  local module="$1" ex_name="$2" ex_id="$3" ex_dir="$4"
  local primary_file="$5"
  local ex_type="${6:-c}"
  local peer_dir="$PEER/$module/$ex_dir"

  if [ "$ex_type" = "c" ]; then
    # C-Aufgaben: Template automatisch anlegen (42-Header, leere Funktion)
    if [ ! -f "$peer_dir/$primary_file" ]; then
      echo -e "\n${CYAN}Lege $module/$ex_id an ...${RESET}"
      bash "$SCRIPTS/new.sh" "$module" "$ex_id"
      echo ""; read -rp "  [Enter] weiter ..." _
    fi
  else
    # Shell-Aufgaben: NUR Verzeichnis anlegen – Dateien erstellt der Lerner selbst!
    mkdir -p "$peer_dir"
  fi

  while true; do
    clear
    echo -e "\n  ${BOLD}▶ $module / $ex_id – $ex_name${RESET}"
    python3 "$SCRIPTS/_ex_status.py" "$PROGRESS" "$module" "$ex_name" 2>/dev/null || true

    if [ "$ex_type" = "c" ]; then
      echo -e "  ${DIM}$peer_dir/$primary_file${RESET}"
      echo ""
      echo -e "   ${BOLD}e${RESET}) Editor      ${BOLD}c${RESET}) Prüfen     ${BOLD}h${RESET}) Hinweise"
      echo -e "   ${BOLD}f${RESET}) Peer fragen ${BOLD}p${RESET}) Aufgabe    ${BOLD}z${RESET}) Zurück"
    else
      # Shell: Verzeichnis zeigen, kein Auto-Editor
      echo -e "\n  ${CYAN}Arbeitsverzeichnis:${RESET}"
      echo -e "  ${BOLD}cd $peer_dir${RESET}"
      echo -e "  ${DIM}(Navigiere selbst hin und erstelle deine Datei(en) – das ist Teil der Aufgabe!)${RESET}"
      echo ""
      echo -e "   ${BOLD}c${RESET}) Prüfen     ${BOLD}h${RESET}) Hinweise    ${BOLD}p${RESET}) Aufgabe lesen"
      echo -e "   ${BOLD}f${RESET}) Peer fragen                     ${BOLD}z${RESET}) Zurück"
    fi
    echo ""
    read -rp "  > " act
    case "$act" in
      e|E)
        if [ "$ex_type" = "c" ]; then
          local ed; ed="$(pick_editor)"
          if [ "$ed" = "code" ]; then
            "$ed" "$peer_dir/$primary_file" >/dev/null 2>&1 &
          else
            "$ed" "$peer_dir/$primary_file"
          fi
        fi
        ;;
      c|C)
        echo ""
        bash "$SCRIPTS/check.sh" "$module" "$ex_id" || true
        echo ""; read -rp "  [Enter] ..." _
        ;;
      h|H) show_hints "$module" "$ex_name" ;;
      f|F) launch_peer "$peer_dir" ;;
      p|P) show_subject "$module" "$ex_name" ;;
      z|Z|q|Q) return ;;
    esac
  done
}

# ── Modulmenü ─────────────────────────────────────────────────────────────────
module_menu() {
  local module="$1" mlow
  mlow=$(echo "$module" | tr '[:upper:]' '[:lower:]')
  local jf="$SUBJECTS/${mlow}_exercises.json"

  mapfile -t EX_IDS   < <(python3 -c "import json; [print(e['id'])   for e in json.load(open('$jf',encoding='utf-8'))['exercises']]")
  mapfile -t EX_NAMES < <(python3 -c "import json; [print(e['name']) for e in json.load(open('$jf',encoding='utf-8'))['exercises']]")
  mapfile -t EX_DIRS  < <(python3 -c "import json; [print(e.get('directory','').rstrip('/')) for e in json.load(open('$jf',encoding='utf-8'))['exercises']]")
  mapfile -t EX_PRIMARY < <(python3 -c "import json; [print(e.get('files',[''])[0]) for e in json.load(open('$jf',encoding='utf-8'))['exercises']]")
  mapfile -t EX_TYPES < <(python3 -c "import json; [print(e.get('type','c')) for e in json.load(open('$jf',encoding='utf-8'))['exercises']]")
  local n="${#EX_IDS[@]}"

  while true; do
    print_global_header
    print_exlist "$module"
    echo -e "\n  ${BOLD}Aktionen${RESET}"
    echo -e "   ${BOLD}1-${n}${RESET}) Übung    ${BOLD}d${RESET}) Dashboard   ${BOLD}t${RESET}) Trophäen   ${BOLD}e${RESET}) Exam"
    echo -e "   ${BOLD}p${RESET}) Peer       ${BOLD}z${RESET}) Modulauswahl"
    echo ""
    read -rp "  > " choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "$n" ]; then
      local i=$((choice - 1))
      exercise_menu "$module" "${EX_NAMES[$i]}" "${EX_IDS[$i]}" "${EX_DIRS[$i]}" "${EX_PRIMARY[$i]}" "${EX_TYPES[$i]}"
    else
      case "$choice" in
        d|D) open_in_browser "$TOOL_ROOT/dashboard.html"; sleep 1 ;;
        p|P) launch_peer "$PEER/$module" ;;
        t|T) clear; bash "$SCRIPTS/trophy.sh"; echo ""; read -rp "  [Enter] ..." _ ;;
        e|E)
          clear; echo -e "${YELLOW}${BOLD}Exam: KEIN Tutor, KEINE Hinweise.${RESET}"
          read -rp "  Wirklich starten? [j/N]: " ok
          [[ "$ok" =~ ^[jJyY]$ ]] && bash "$TOOL_ROOT/exam/exam.sh" --module "$module"
          echo ""; read -rp "  [Enter] ..." _
          ;;
        z|Z|q|Q) return ;;
      esac
    fi
  done
}

# ── Hauptmenü ─────────────────────────────────────────────────────────────────
main_menu() {
  while true; do
    print_global_header
    print_module_list
    local n_modules; n_modules=$(get_n_modules)
    echo -e "\n  ${BOLD}Aktionen${RESET}"
    echo -e "   ${BOLD}1-${n_modules}${RESET}) Modul    ${BOLD}d${RESET}) Dashboard   ${BOLD}t${RESET}) Trophäen"
    echo -e "   ${BOLD}p${RESET}) Peer       ${BOLD}g${RESET}) Git-Status   ${BOLD}q${RESET}) Beenden"
    echo ""
    read -rp "  > " choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "$n_modules" ]; then
      local module_id; module_id=$(resolve_module_by_index "$choice")
      [ -n "$module_id" ] && module_menu "$module_id"
    else
      case "$choice" in
        d|D) open_in_browser "$TOOL_ROOT/dashboard.html"; sleep 1 ;;
        p|P) launch_peer ;;
        t|T) clear; bash "$SCRIPTS/trophy.sh"; echo ""; read -rp "  [Enter] ..." _ ;;
        g|G)
          clear; echo -e "${BOLD}Git-Status:${RESET}\n"
          ( cd "$REPO_ROOT" && git status --short && echo "" && git log --oneline -5 2>/dev/null )
          echo -e "\n${CYAN}Commit:${RESET}  cd \"$REPO_ROOT\" && git add -A && git commit -m \"...\" && git push"
          echo ""; read -rp "  [Enter] ..." _
          ;;
        q|Q) clear; echo -e "${PURPLE}Bis bald! 🚀${RESET}\n"; exit 0 ;;
      esac
    fi
  done
}

main_menu
    echo -e "   ${BOLD}p${RESET}) Peer       ${BOLD}g${RESET}) Git-Status   ${BOLD}q${RESET}) Beenden"
    echo ""
    read -rp "  > " choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "$n_modules" ]; then
      local module_id; module_id=$(resolve_module_by_index "$choice")
      [ -n "$module_id" ] && module_menu "$module_id"
    else
      case "$choice" in
        d|D) open_in_browser "$TOOL_ROOT/dashboard.html"; sleep 1 ;;
        p|P) launch_peer ;;
        t|T) clear; bash "$SCRIPTS/trophy.sh"; echo ""; read -rp "  [Enter] ..." _ ;;
        g|G)
          clear; echo -e "${BOLD}Git-Status:${RESET}\n"
          ( cd "$REPO_ROOT" && git status --short && echo "" && git log --oneline -5 2>/dev/null )
          echo -e "\n${CYAN}Commit:${RESET}  cd \"$REPO_ROOT\" && git add -A && git commit -m \"...\" && git push"
          echo ""; read -rp "  [Enter] ..." _
          ;;
        q|Q) clear; echo -e "${PURPLE}Bis bald! 🚀${RESET}\n"; exit 0 ;;
      esac
    fi
  done
}

main_menu
