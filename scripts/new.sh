#!/bin/bash
# =============================================================================
# 42 Lerntool – new.sh  (generisch, Multi-Modul)
# Legt Übungsverzeichnis + Datei(en) mit 42-Header an
# Usage: bash scripts/new.sh <MODULE> <exercise_name|ex_id>
#   z.B.: bash scripts/new.sh C00 ft_putchar
#         bash scripts/new.sh C00 ex00
#         bash scripts/new.sh Shell00 ex04
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOL_ROOT="$(dirname "$SCRIPT_DIR")"

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; RESET='\033[0m'

# ─── Argumente ───────────────────────────────────────────────────────────────
if [ $# -lt 2 ]; then
  echo "Usage: bash scripts/new.sh <MODULE> <exercise_name|ex_id>"
  echo "  Beispiele: bash scripts/new.sh C00 ft_putchar"
  echo "             bash scripts/new.sh Shell00 ex04"
  exit 1
fi

MODULE="$1"
ARG="$2"

# ─── Modul-JSON laden ────────────────────────────────────────────────────────
MODULE_LOWER=$(echo "$MODULE" | tr '[:upper:]' '[:lower:]')
JSON_FILE="$TOOL_ROOT/subjects/${MODULE_LOWER}_exercises.json"
if [ ! -f "$JSON_FILE" ]; then
  echo -e "${YELLOW}Kein Subject-JSON für '$MODULE': $JSON_FILE${RESET}"
  exit 1
fi

# ─── Übung auflösen ──────────────────────────────────────────────────────────
EX_JSON=$(python3 -c "
import json, sys
data = json.load(open('$JSON_FILE', encoding='utf-8'))
arg = '$ARG'.lower()
for ex in data['exercises']:
    if ex['id'].lower() == arg or ex['name'].lower() == arg:
        print(json.dumps(ex))
        sys.exit(0)
sys.exit(1)
" 2>/dev/null)

if [ -z "$EX_JSON" ]; then
  echo -e "${YELLOW}Unbekannte Übung: '$ARG' in $MODULE${RESET}"
  python3 -c "
import json
d = json.load(open('$JSON_FILE', encoding='utf-8'))
for e in d['exercises']:
    print(f\"  {e['id']}  {e['name']}\")
"
  exit 1
fi

EX_ID=$(    echo "$EX_JSON" | python3 -c "import json,sys; e=json.load(sys.stdin); print(e['id'])")
EX_NAME=$(  echo "$EX_JSON" | python3 -c "import json,sys; e=json.load(sys.stdin); print(e['name'])")
EX_TYPE=$(  echo "$EX_JSON" | python3 -c "import json,sys; e=json.load(sys.stdin); print(e.get('type','c'))")
EX_DIR=$(   echo "$EX_JSON" | python3 -c "import json,sys; e=json.load(sys.stdin); print(e.get('directory','').rstrip('/'))")
EX_FILES=$( echo "$EX_JSON" | python3 -c "import json,sys; e=json.load(sys.stdin); print(' '.join(e.get('files',[])))")
EX_PROTO=$( echo "$EX_JSON" | python3 -c "import json,sys; e=json.load(sys.stdin); print(e.get('prototype',''))" 2>/dev/null || echo "")
EX_ALLOWED=$(echo "$EX_JSON"| python3 -c "import json,sys; e=json.load(sys.stdin); print(', '.join(e.get('allowed_functions',[])))" 2>/dev/null || echo "")
EX_DESC=$(  echo "$EX_JSON" | python3 -c "import json,sys; e=json.load(sys.stdin); print(e.get('description_de') or e.get('description',''))" 2>/dev/null || echo "")

PEER_DIR="$TOOL_ROOT/peer/$MODULE/$EX_DIR"
mkdir -p "$PEER_DIR"

NOW=$(date +"%Y/%m/%d %H:%M:%S")
YEAR=$(date +"%Y")
CREATED=0

for FILE in $EX_FILES; do
  DEST="$PEER_DIR/$FILE"
  if [ -f "$DEST" ]; then
    echo -e "${YELLOW}Existiert bereits: $DEST${RESET}"
    continue
  fi

  # Datei-Typ bestimmen
  EXT="${FILE##*.}"

  if [ "$EXT" = "c" ] || [ "$EXT" = "h" ]; then
    # C-Datei: 42-Header + leere Funktion
    PROTO_CLEAN=$(echo "$EX_PROTO" | sed 's/;$//')
    FNAME_PAD=$(printf "%-51s" "$FILE")
    cat > "$DEST" << TEMPLATE
/* ************************************************************************** */
/*                                                                            */
/*   ${FNAME_PAD}:+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: rene <rene@42.fr>                          +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: $NOW by rene              #+#    #+#             */
/*   Updated: $NOW by rene             ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include <unistd.h>

${PROTO_CLEAN}
{
	/* TODO */
}
TEMPLATE

  elif [ "$EXT" = "sh" ]; then
    # Shell-Skript: Shebang + Kommentar
    cat > "$DEST" << TEMPLATE
#!/bin/sh
# $FILE – $MODULE $EX_ID
# $EX_DESC

# TODO
TEMPLATE
    chmod +x "$DEST"

  else
    # Andere Dateitypen (z.B. leere Datei für Shell00 ex00 'z')
    touch "$DEST"
  fi

  echo -e "${GREEN}${BOLD}✓${RESET} Angelegt: ${CYAN}$DEST${RESET}"
  CREATED=$((CREATED + 1))
done

echo ""
if [ "$CREATED" -eq 0 ]; then
  echo -e "Alle Dateien existieren bereits. Direkt editieren:"
else
  echo -e "${BOLD}Aufgabe:${RESET}  $EX_DESC"
  [ -n "$EX_PROTO"   ] && echo -e "${BOLD}Prototyp:${RESET} $EX_PROTO"
  [ -n "$EX_ALLOWED" ] && echo -e "${BOLD}Erlaubt:${RESET}  $EX_ALLOWED"
  echo ""
  echo -e "Nächste Schritte:"
fi
echo -e "  Editieren: ${CYAN}nano $PEER_DIR/$(echo "$EX_FILES" | cut -d' ' -f1)${RESET}"
echo -e "  Prüfen:    ${CYAN}bash $SCRIPT_DIR/check.sh $MODULE $EX_ID${RESET}"
echo ""
