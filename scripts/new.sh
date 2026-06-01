#!/bin/bash
# =============================================================================
# 42 Lerntool – new.sh
# Legt Übungsverzeichnis + .c-Template an
# Usage: bash scripts/new.sh <exercise_name>
#   z.B.: bash scripts/new.sh ft_print_reverse_alphabet
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOL_ROOT="$(dirname "$SCRIPT_DIR")"
PEER_DIR="$TOOL_ROOT/peer"

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; RESET='\033[0m'

EX_NAME="${1:-}"
if [ -z "$EX_NAME" ]; then
  echo "Usage: bash scripts/new.sh <exercise_name>"
  echo "Beispiel: bash scripts/new.sh ft_print_reverse_alphabet"
  exit 1
fi

# Lookup: Prototyp + erlaubte Funktionen aus JSON
PROTO=$(python3 -c "
import json
ex = json.load(open('$TOOL_ROOT/subjects/c00_exercises.json'))
for e in ex['exercises']:
    if e['name'] == '$EX_NAME':
        print(e['prototype'].rstrip().rstrip(';'))
        break
" 2>/dev/null)

ALLOWED=$(python3 -c "
import json
ex = json.load(open('$TOOL_ROOT/subjects/c00_exercises.json'))
for e in ex['exercises']:
    if e['name'] == '$EX_NAME':
        print(', '.join(e['allowed_functions']))
        break
" 2>/dev/null)

DESC=$(python3 -c "
import json
ex = json.load(open('$TOOL_ROOT/subjects/c00_exercises.json'))
for e in ex['exercises']:
    if e['name'] == '$EX_NAME':
        print(e['description'])
        break
" 2>/dev/null)

EX_DIR="$PEER_DIR/$EX_NAME"
C_FILE="$EX_DIR/${EX_NAME}.c"

mkdir -p "$EX_DIR"

if [ -f "$C_FILE" ]; then
  echo -e "${YELLOW}Datei existiert bereits: $C_FILE${RESET}"
  echo -e "Direkt editieren, dann: ${CYAN}bash scripts/check.sh $EX_NAME${RESET}"
  exit 0
fi

# Heutiges Datum
NOW=$(date +"%Y/%m/%d %H:%M:%S")
YEAR=$(date +"%Y")

# 42-Header + leere Funktion schreiben
cat > "$C_FILE" << TEMPLATE
/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   ${EX_NAME}.c$(printf '%*s' $((53 - ${#EX_NAME} - 2)) ''):+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: rene <rene@42.fr>                          +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: $NOW by rene              #+#    #+#             */
/*   Updated: $NOW by rene             ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include <unistd.h>

/* ${DESC} */
/* Erlaubt: ${ALLOWED} */

${PROTO}
{
	/* TODO */
}
TEMPLATE

echo -e "\n${GREEN}${BOLD}✓ Datei angelegt:${RESET} ${CYAN}$C_FILE${RESET}"
echo ""
echo -e "${BOLD}Aufgabe:${RESET} $DESC"
echo -e "${BOLD}Prototyp:${RESET} $PROTO"
echo -e "${BOLD}Erlaubt:${RESET}  $ALLOWED"
echo ""
echo -e "Nächste Schritte:"
echo -e "  1. Datei editieren:  ${CYAN}nano $C_FILE${RESET}"
echo -e "                 oder: ${CYAN}code $C_FILE${RESET}  (falls VS Code installiert)"
echo -e "  2. Testen:           ${CYAN}bash scripts/check.sh $EX_NAME${RESET}"
echo -e "  3. Bestanden?        ${CYAN}bash scripts/update_progress.sh $EX_NAME <score>${RESET}"
echo ""
