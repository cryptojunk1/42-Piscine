#!/bin/bash
# =============================================================================
# migrate_structure.sh
# Migriert alte peer/<funcname>/<funcname>.c  →  peer/C00/<exNN>/<funcname>.c
# Einmalig ausführen! Danach ist die neue Struktur aktiv.
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOL_ROOT="$(dirname "$SCRIPT_DIR")"
PEER="$TOOL_ROOT/peer"
JSON="$TOOL_ROOT/subjects/c00_exercises.json"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

echo -e "${BOLD}42 Lerntool – Struktur-Migration${RESET}"
echo -e "Alte Struktur: peer/<name>/<name>.c"
echo -e "Neue Struktur: peer/C00/<exID>/<name>.c"
echo ""

# Mapping aus JSON lesen
python3 - "$JSON" "$PEER" << 'PY'
import json, os, shutil, sys

json_file, peer = sys.argv[1], sys.argv[2]
d  = json.load(open(json_file, encoding="utf-8"))

for ex in d["exercises"]:
    name  = ex["name"]
    ex_id = ex["id"]
    ex_dir= ex.get("directory","").rstrip("/")
    files = ex.get("files", [name + ".c"])

    old_dir = os.path.join(peer, name)
    new_dir = os.path.join(peer, "C00", ex_dir)

    for fname in files:
        old_file = os.path.join(old_dir, fname)
        if not os.path.isfile(old_file):
            print(f"  · {name}/{fname} – nicht vorhanden, überspringe")
            continue
        os.makedirs(new_dir, exist_ok=True)
        new_file = os.path.join(new_dir, fname)
        if os.path.isfile(new_file):
            print(f"  ⚠ {new_file} – existiert bereits, überspringe")
            continue
        shutil.copy2(old_file, new_file)
        print(f"  \033[0;32m✓\033[0m {old_file} → {new_file}")

print("\nMigration abgeschlossen.")
print("Alte Verzeichnisse (peer/<name>/) wurden NICHT gelöscht – kannst du manuell prüfen und löschen.")
PY

echo ""
echo -e "${CYAN}Alte Verzeichnisse löschen (nach Prüfung):${RESET}"
echo -e "  rm -rf $PEER/ft_putchar $PEER/ft_print_alphabet $PEER/ft_print_reverse_alphabet"
