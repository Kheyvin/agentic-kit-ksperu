#!/usr/bin/env bash
# PostToolUse(Write|Edit): comprueba la sintaxis del archivo recién escrito.
# No formatea ni modifica nada: un formateador que reescribe el archivo rompe el siguiente Edit del agente.
set -uo pipefail
INPUT="$(cat)"
command -v php >/dev/null 2>&1 || exit 0
FILE="$(printf '%s' "$INPUT" | php -r '$d=json_decode(stream_get_contents(STDIN),true); echo $d["tool_input"]["file_path"] ?? "";' 2>/dev/null)"
[ -n "$FILE" ] && [ -f "$FILE" ] || exit 0
case "$FILE" in
  *.php) OUT="$(php -l "$FILE" 2>&1)" || { echo "Error de sintaxis PHP en $FILE: $OUT" >&2; exit 2; } ;;
esac
exit 0
